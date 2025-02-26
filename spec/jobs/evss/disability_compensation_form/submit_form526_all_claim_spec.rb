# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EVSS::DisabilityCompensationForm::SubmitForm526AllClaim, type: :job do
  subject { described_class }

  before do
    Sidekiq::Worker.clear_all
  end

  let(:user) { FactoryBot.create(:user, :loa3) }
  let(:auth_headers) do
    EVSS::DisabilityCompensationAuthHeaders.new(user).add_headers(EVSS::AuthHeaders.new(user).to_h)
  end

  describe '.perform_async' do
    let(:saved_claim) { FactoryBot.create(:va526ez) }
    let(:submitted_claim_id) { 600_130_094 }
    let(:submission) do
      create(:form526_submission,
             user_uuid: user.uuid,
             auth_headers_json: auth_headers.to_json,
             saved_claim_id: saved_claim.id)
    end
    let(:open_claims_cassette) { 'evss/claims/claims_without_open_compensation_claims' }
    let(:rated_disabilities_cassette) { 'evss/disability_compensation_form/rated_disabilities' }
    let(:submit_form_cassette) { 'evss/disability_compensation_form/submit_form_v2' }
    let(:cassettes) { [open_claims_cassette, rated_disabilities_cassette, submit_form_cassette] }

    before do
      cassettes.each { |cassette| VCR.insert_cassette(cassette) }
    end

    after do
      cassettes.each { |cassette| VCR.eject_cassette(cassette) }
    end

    def expect_retryable_error(error_class)
      subject.perform_async(submission.id)
      expect_any_instance_of(Sidekiq::Form526JobStatusTracker::Metrics).to receive(:increment_retryable).once
      expect(Form526JobStatus).to receive(:upsert).twice
      expect { described_class.drain }.to raise_error(error_class)
    end

    context 'with a successful submission job' do
      it 'queues a job for submit' do
        expect do
          subject.perform_async(submission.id)
        end.to change(subject.jobs, :size).by(1)
      end

      it 'submits successfully' do
        subject.perform_async(submission.id)
        described_class.drain
        expect(Form526JobStatus.last.status).to eq 'success'
      end

      context 'with an MAS-related diagnostic code' do
        let(:submission) do
          create(:form526_submission,
                 :non_rrd_with_mas_diagnostic_code,
                 user_uuid: user.uuid,
                 auth_headers_json: auth_headers.to_json,
                 saved_claim_id: saved_claim.id)
        end
        let(:mas_cassette) { 'mail_automation/mas_initiate_apcas_request' }
        let(:cassettes) do
          [open_claims_cassette, rated_disabilities_cassette, submit_form_cassette, mas_cassette]
        end

        it 'sends form526 to the MAS endpoint successfully' do
          subject.perform_async(submission.id)
          described_class.drain
          expect(Form526JobStatus.last.status).to eq 'success'
          rrd_submission = Form526Submission.find(Form526JobStatus.last.form526_submission_id)
          expect(rrd_submission.form.dig('rrd_metadata', 'mas_packetId')).to eq '12345'
        end

        it 'sends an email for tracking purposes' do
          subject.perform_async(submission.id)
          described_class.drain
          expect(ActionMailer::Base.deliveries.last.subject).to eq 'MA claim - 6847'
        end

        context 'when MAS endpoint handshake fails' do
          let(:mas_cassette) { 'mail_automation/mas_initiate_apcas_request_failure' }

          it 'handles MAS endpoint handshake failure by sending failure notification' do
            subject.perform_async(submission.id)
            described_class.drain
            expect(ActionMailer::Base.deliveries.last.subject).to eq "Failure: MA claim - #{submitted_claim_id}"
          end
        end

        context 'when not all claims are handed off to MAS' do
          before { Flipper.disable(:rrd_mas_all_claims_notification) }
          after { Flipper.enable(:rrd_mas_all_claims_notification) }

          it 'includes a proper classification code for EVSS submission' do
            subject.perform_async(submission.id)
            described_class.drain
            mas_submission = Form526Submission.find(Form526JobStatus.last.form526_submission_id)
            expect(mas_submission.form.dig('form526', 'form526',
                                           'disabilities').first['classificationCode']).to eq '9012'
          end
        end

        context 'MAS-related claim that already includes classification code' do
          let(:submission) do
            create(:form526_submission,
                   :mas_diagnostic_code_with_classification,
                   user_uuid: user.uuid,
                   auth_headers_json: auth_headers.to_json,
                   saved_claim_id: saved_claim.id)
          end

          it 'already includes classification code and does not modify' do
            subject.perform_async(submission.id)
            described_class.drain
            mas_submission = Form526Submission.find(Form526JobStatus.last.form526_submission_id)
            expect(mas_submission.form.dig('form526', 'form526',
                                           'disabilities').first['classificationCode']).to eq '8935'
          end
        end

        context 'when the rated disability has decision code NOTSVCCON in EVSS' do
          let(:rated_disabilities_cassette) do
            'evss/disability_compensation_form/rated_disabilities_with_non_service_connected'
          end

          it 'skips forwarding to MAS' do
            subject.perform_async(submission.id)
            described_class.drain
            expect(Form526JobStatus.last.status).to eq 'success'
            rrd_submission = Form526Submission.find(submission.id)
            expect(rrd_submission.form.dig('rrd_metadata', 'mas_packetId')).to be_nil
          end
        end
      end

      context 'with multiple MAS-related diagnostic codes' do
        let(:submission) do
          create(:form526_submission,
                 :with_multiple_mas_diagnostic_code,
                 user_uuid: user.uuid,
                 auth_headers_json: auth_headers.to_json,
                 saved_claim_id: saved_claim.id)
        end

        context 'when tracking but not APCAS notification is enabled for all claims' do
          it 'sends only one email' do
            Flipper.enable(:rrd_mas_all_claims_tracking)
            Flipper.disable(:rrd_mas_all_claims_notification)
            subject.perform_async(submission.id)
            described_class.drain
            expect(ActionMailer::Base.deliveries.length).to eq 1
          end
        end

        context 'when tracking and APCAS notification are enabled for all claims' do
          it 'calls APCAS and sends two emails' do
            Flipper.enable(:rrd_mas_all_claims_tracking)
            Flipper.enable(:rrd_mas_all_claims_notification)
            VCR.use_cassette('mail_automation/mas_initiate_apcas_request') do
              subject.perform_async(submission.id)
            end
            described_class.drain
            expect(ActionMailer::Base.deliveries.length).to eq 2
          end
        end

        context 'when all claims tracking is disabled' do
          it 'does not send an email' do
            Flipper.disable(:rrd_mas_all_claims_tracking)
            subject.perform_async(submission.id)
            described_class.drain
            expect(ActionMailer::Base.deliveries.length).to eq 0
          end
        end
      end

      context 'with PACT-related disability' do
        let(:submission) do
          create(:form526_submission,
                 :with_pact_related_disabilities,
                 user_uuid: user.uuid,
                 auth_headers_json: auth_headers.to_json,
                 saved_claim_id: saved_claim.id)
        end

        it 'sends an email' do
          VCR.use_cassette('rrd/hypertension', match_requests_on: %i[host path method]) do
            subject.perform_async(submission.id)
            described_class.drain
            expect(ActionMailer::Base.deliveries.last.body.include?('Number of BP readings: 0')).to eq true
            expect(ActionMailer::Base.deliveries.last.body.include?('Number of Active Medications: 11')).to eq true
            expect(ActionMailer::Base.deliveries.last.body.include?('Number of claimed issues: 3')).to eq true
            expect(ActionMailer::Base.deliveries.last.subject).to eq "NEW claim - #{submitted_claim_id}"
          end
        end
      end
    end

    context 'with non-MAS-related diagnostic code' do
      let(:submission) do
        create(:form526_submission,
               :with_uploads,
               user_uuid: user.uuid,
               auth_headers_json: auth_headers.to_json,
               saved_claim_id: saved_claim.id)
      end

      it 'does not set a classification code for irrelevant claims' do
        subject.perform_async(submission.id)
        described_class.drain
        mas_submission = Form526Submission.find(Form526JobStatus.last.form526_submission_id)
        expect(mas_submission.form.dig('form526', 'form526',
                                       'disabilities').first['classificationCode']).to eq '8935'
      end
    end

    context 'when retrying a job' do
      it 'doesnt recreate the job status' do
        subject.perform_async(submission.id)

        jid = subject.jobs.last['jid']
        values = {
          form526_submission_id: submission.id,
          job_id: jid,
          job_class: subject.class,
          status: Form526JobStatus::STATUS[:try],
          updated_at: Time.now.utc
        }
        Form526JobStatus.upsert(values, unique_by: :job_id)
        expect_any_instance_of(Sidekiq::Form526JobStatusTracker::Metrics).to(
          receive(:increment_success).with(false).once
        )
        described_class.drain
        job_status = Form526JobStatus.where(job_id: values[:job_id]).first
        expect(job_status.status).to eq 'success'
        expect(job_status.error_class).to eq nil
        expect(job_status.job_class).to eq 'SubmitForm526AllClaim'
        expect(Form526JobStatus.count).to eq 1
      end
    end

    context 'with a submission timeout' do
      before do
        allow_any_instance_of(Faraday::Connection).to receive(:post).and_raise(Faraday::TimeoutError)
      end

      it 'runs the retryable_error_handler and raises a EVSS::DisabilityCompensationForm::GatewayTimeout' do
        subject.perform_async(submission.id)
        expect_any_instance_of(Sidekiq::Form526JobStatusTracker::Metrics).to receive(:increment_retryable).once
        expect(Rails.logger).to receive(:error).once
        expect { described_class.drain }.to raise_error(Common::Exceptions::GatewayTimeout)
        job_status = Form526JobStatus.find_by(form526_submission_id: submission.id,
                                              job_class: 'SubmitForm526AllClaim')
        expect(job_status.status).to eq 'retryable_error'
        expect(job_status.error_class).to eq 'Common::Exceptions::GatewayTimeout'
        expect(job_status.error_message).to eq 'Gateway timeout'
      end
    end

    context 'with a 503 error' do
      it 'runs the retryable_error_handler and raises a ServiceUnavailableException' do
        expect_any_instance_of(EVSS::DisabilityCompensationForm::Service).to receive(:submit_form526).and_raise(
          EVSS::DisabilityCompensationForm::ServiceUnavailableException
        )
        expect(Rails.logger).to receive(:error).once
        expect_retryable_error(EVSS::DisabilityCompensationForm::ServiceUnavailableException)
      end
    end

    context 'with a breakers outage' do
      it 'runs the retryable_error_handler and raises a gateway timeout' do
        allow_any_instance_of(Form526Submission).to receive(:prepare_for_evss!).and_return(nil)
        EVSS::DisabilityCompensationForm::Configuration.instance.breakers_service.begin_forced_outage!
        expect(Rails.logger).to receive(:error).once
        expect_retryable_error(Breakers::OutageException)
        EVSS::DisabilityCompensationForm::Configuration.instance.breakers_service.end_forced_outage!
      end
    end

    context 'with a client error' do
      it 'sets the job_status to "non_retryable_error"' do
        VCR.use_cassette('evss/disability_compensation_form/submit_400') do
          expect_any_instance_of(described_class).to receive(:log_exception_to_sentry)
          subject.perform_async(submission.id)
          expect_any_instance_of(Sidekiq::Form526JobStatusTracker::Metrics).to receive(:increment_non_retryable).once
          described_class.drain
          form_job_status = Form526JobStatus.last
          expect(form_job_status.error_class).to eq 'EVSS::DisabilityCompensationForm::ServiceException'
          expect(form_job_status.job_class).to eq 'SubmitForm526AllClaim'
          expect(form_job_status.status).to eq Form526JobStatus::STATUS[:non_retryable_error]
          expect(form_job_status.error_message).to eq(
            '[{"key"=>"form526.serviceInformation.ConfinementPastActiveDutyDate", "severity"=>"ERROR", "text"=>"The ' \
            'confinement start date is too far in the past"}, {"key"=>"form526.serviceInformation.' \
            'ConfinementWithInServicePeriod", "severity"=>"ERROR", "text"=>"Your period of confinement must be ' \
            'within a single period of service"}, {"key"=>"form526.veteran.homelessness.pointOfContact.' \
            'pointOfContactName.Pattern", "severity"=>"ERROR", "text"=>"must match \\"([a-zA-Z0-9-/]+( ?))*$\\""}]'
          )
        end
      end
    end

    context 'with an upstream service error' do
      it 'sets the transaction to "retrying"' do
        VCR.use_cassette('evss/disability_compensation_form/submit_500_with_err_msg') do
          expect(Rails.logger).to receive(:error).twice
          expect_retryable_error(EVSS::DisabilityCompensationForm::ServiceException)
        end
      end
    end

    context 'with an upstream bad gateway' do
      it 'sets the transaction to "retrying"' do
        VCR.use_cassette('evss/disability_compensation_form/submit_502') do
          expect(Rails.logger).to receive(:error).twice
          expect_retryable_error(Common::Exceptions::BackendServiceException)
        end
      end
    end

    context 'with an upstream service unavailable' do
      it 'sets the transaction to "retrying"' do
        VCR.use_cassette('evss/disability_compensation_form/submit_503') do
          expect(Rails.logger).to receive(:error).twice
          expect_retryable_error(EVSS::DisabilityCompensationForm::ServiceUnavailableException)
        end
      end
    end

    context 'with an upstream service error for EP code not valid' do
      it 'sets the transaction to "non_retryable_error"' do
        VCR.use_cassette('evss/disability_compensation_form/submit_200_with_ep_not_valid') do
          subject.perform_async(submission.id)
          expect_any_instance_of(Sidekiq::Form526JobStatusTracker::Metrics).to receive(:increment_non_retryable).once
          described_class.drain
          expect(Form526JobStatus.last.status).to eq Form526JobStatus::STATUS[:non_retryable_error]
        end
      end
    end

    context 'with a max ep code server error' do
      it 'sets the transaction to "non_retryable_error"' do
        VCR.use_cassette('evss/disability_compensation_form/submit_500_with_max_ep_code') do
          subject.perform_async(submission.id)
          expect_any_instance_of(Sidekiq::Form526JobStatusTracker::Metrics).to receive(:increment_non_retryable).once
          described_class.drain
          expect(Form526JobStatus.last.status).to eq Form526JobStatus::STATUS[:non_retryable_error]
        end
      end
    end

    context 'with a unused [418] error' do
      it 'sets the transaction to "retryable_error"' do
        VCR.use_cassette('evss/disability_compensation_form/submit_200_with_418') do
          subject.perform_async(submission.id)
          expect_any_instance_of(Sidekiq::Form526JobStatusTracker::Metrics).to receive(:increment_retryable).once
          expect { described_class.drain }.to raise_error(EVSS::DisabilityCompensationForm::ServiceException)
          expect(Form526JobStatus.last.status).to eq Form526JobStatus::STATUS[:retryable_error]
        end
      end
    end

    context 'with a BGS error' do
      it 'sets the transaction to "retryable_error"' do
        VCR.use_cassette('evss/disability_compensation_form/submit_200_with_bgs_error') do
          subject.perform_async(submission.id)
          expect_any_instance_of(Sidekiq::Form526JobStatusTracker::Metrics).to receive(:increment_retryable).once
          expect { described_class.drain }.to raise_error(EVSS::DisabilityCompensationForm::ServiceException)
          expect(Form526JobStatus.last.status).to eq Form526JobStatus::STATUS[:retryable_error]
        end
      end
    end

    context 'with a pif in use server error' do
      it 'sets the transaction to "non_retryable_error"' do
        VCR.use_cassette('evss/disability_compensation_form/submit_500_with_pif_in_use') do
          subject.perform_async(submission.id)
          expect_any_instance_of(Sidekiq::Form526JobStatusTracker::Metrics).to receive(:increment_non_retryable).once
          described_class.drain
          expect(Form526JobStatus.last.status).to eq Form526JobStatus::STATUS[:non_retryable_error]
        end
      end
    end

    context 'with a VeteranRecordWsClientException java error' do
      it 'sets the transaction to "retryable_error"' do
        VCR.use_cassette('evss/disability_compensation_form/submit_500_with_java_ws_error') do
          subject.perform_async(submission.id)
          expect_any_instance_of(Sidekiq::Form526JobStatusTracker::Metrics).to receive(:increment_retryable).once
          expect { described_class.drain }.to raise_error(EVSS::DisabilityCompensationForm::ServiceException)
          expect(Form526JobStatus.last.status).to eq Form526JobStatus::STATUS[:retryable_error]
        end
      end
    end

    context 'with an error that is not mapped' do
      it 'sets the transaction to "retrying"' do
        VCR.use_cassette('evss/disability_compensation_form/submit_500_with_unmapped') do
          subject.perform_async(submission.id)
          described_class.drain
          expect(Form526JobStatus.last.status).to eq Form526JobStatus::STATUS[:non_retryable_error]
        end
      end
    end

    context 'with an unexpected error' do
      before do
        allow_any_instance_of(Faraday::Connection).to receive(:post).and_raise(StandardError.new('foo'))
      end

      it 'sets the transaction to "non_retryable_error"' do
        subject.perform_async(submission.id)
        described_class.drain
        expect(Form526JobStatus.last.status).to eq Form526JobStatus::STATUS[:non_retryable_error]
      end
    end

    context 'with an RRD claim' do
      before do
        allow_any_instance_of(RapidReadyForDecision::SidekiqJobSelector).to receive(:rrd_applicable?).and_return(true)
      end

      context 'with a non-retryable (unexpected) error' do
        before do
          allow_any_instance_of(Faraday::Connection).to receive(:post).and_raise(StandardError.new('foo'))
        end

        it 'sends a "non-retryable" RRD alert' do
          expect_any_instance_of(described_class).to receive(:send_rrd_alert).with(anything, anything, 'non-retryable')
          subject.perform_async(submission.id)
          described_class.drain
          expect(Form526JobStatus.last.status).to eq Form526JobStatus::STATUS[:non_retryable_error]
        end
      end
    end
  end
end
