# frozen_string_literal: true

require 'rails_helper'
require AppealsApi::Engine.root.join('spec', 'spec_helper.rb')

describe AppealsApi::SupplementalClaim, type: :model do
  include FixtureHelpers

  let(:default_auth_headers) { fixture_as_json 'valid_200995_headers.json', version: 'v2' }
  let(:default_form_data) { fixture_as_json 'valid_200995.json', version: 'v2' }

  let(:supplemental_claim_veteran_only) { create(:supplemental_claim) }
  let(:sc_with_nvc) { create(:extra_supplemental_claim) }

  it_behaves_like 'an appeal model with updatable status' do
    let(:example_instance) { supplemental_claim_veteran_only }
    let(:instance_without_email) do
      described_class.create!(
        auth_headers: default_auth_headers,
        api_version: 'V2',
        form_data: default_form_data.deep_merge(
          { 'data' => { 'attributes' => { 'veteran' => { 'email' => nil } } } }
        )
      )
    end
  end

  describe 'validations' do
    let(:appeal) { build(:extra_supplemental_claim) }

    it_behaves_like 'shared model validations', validations: %i[veteran_birth_date_is_in_the_past
                                                                contestable_issue_dates_are_in_the_past
                                                                required_claimant_data_is_present],
                                                required_claimant_headers: described_class.required_nvc_headers

    context "when 'claimant' fields provided by 'claimantType' is 'veteran'" do
      it 'errors with pointer to claimant type attribute' do
        appeal.form_data['data']['attributes']['claimantType'] = 'veteran'

        expect(appeal.valid?).to be false
        expect(appeal.errors.size).to eq 1
        error = appeal.errors.first
        expect(error.attribute).to eq(:'/data/attributes/claimantType')
        expect(error.message).to eq "If '/data/attributes/claimant' field is supplied, " \
                                    "'data/attributes/claimantType' must not be 'veteran'"
      end
    end

    context "when 'evidenceSubmission' fields have invalid date ranges under 'retrieveFrom'" do
      it 'errors with a point to the offending evidenceDates index' do
        retrieve_from = appeal.form_data['data']['attributes']['evidenceSubmission']['retrieveFrom']
        retrieve_from[2]['attributes']['evidenceDates'][0]['startDate'] = '2020-05-10'

        expect(appeal.valid?).to be false
        expect(appeal.errors.size).to eq 1
        error = appeal.errors.first
        expect(error.attribute).to eq(
          :"/data/attributes/evidenceSubmission/retrieveFrom[2]/attributes/evidenceDates[0]"
        )
        expect(error.message).to eq '2020-05-10 must before or the same day as 2020-04-10. '\
                                    'Both dates must also be in the past.'
      end
    end
  end

  describe '#veteran_dob_month' do
    it { expect(sc_with_nvc.veteran_dob_month).to eq '12' }
  end

  describe '#veteran_dob_day' do
    it { expect(sc_with_nvc.veteran_dob_day).to eq '31' }
  end

  describe '#veteran_dob_year' do
    it { expect(sc_with_nvc.veteran_dob_year).to eq '1969' }
  end

  describe '#consumer_name' do
    it { expect(sc_with_nvc.consumer_name).to eq 'va.gov' }
  end

  describe '#consumer_id' do
    it { expect(sc_with_nvc.consumer_id).to eq 'some-guid' }
  end

  describe '#benefit_type' do
    it { expect(sc_with_nvc.benefit_type).to eq 'compensation' }
  end

  describe '#claimant_type' do
    it { expect(sc_with_nvc.claimant_type).to eq 'other' }
  end

  describe '#claimant_type_other_text' do
    it { expect(sc_with_nvc.claimant_type_other_text).to eq 'Veteran Attorney' }
  end

  describe '#contestable_issues' do
    subject { sc_with_nvc.contestable_issues.to_json }

    it 'matches json' do
      form_data = sc_with_nvc.form_data
      issues = form_data['included'].map { |issue| AppealsApi::ContestableIssue.new(issue) }.to_json

      expect(subject).to eq(issues)
    end
  end

  describe '#evidence_submission_days_window' do
    it { expect(sc_with_nvc.evidence_submission_days_window).to eq 7 }
  end

  describe '#accepts_evidence?' do
    it { expect(sc_with_nvc.accepts_evidence?).to be true }
  end

  describe '#outside_submission_window_error' do
    error = {
      title: 'unprocessable_entity',
      detail: 'This submission is outside of the 7-day window for evidence submission',
      code: 'OutsideSubmissionWindow',
      status: '422'
    }

    it { expect(sc_with_nvc.outside_submission_window_error).to eq error }
  end

  describe '#soc_opt_in' do
    it { expect(sc_with_nvc.soc_opt_in).to be true }
  end

  describe '#form_5103_notice_acknowledged' do
    it { expect(sc_with_nvc.form_5103_notice_acknowledged).to be true }
  end

  describe '#date_signed' do
    subject { sc_with_nvc.date_signed }

    it('matches json') do
      expect(subject).to eq(
        Time.now.in_time_zone(sc_with_nvc.signing_appellant.timezone).strftime('%m/%d/%Y')
      )
    end
  end

  describe '#stamp_text' do
    let(:default_auth_headers) { fixture_as_json 'valid_200995_headers.json', version: 'v2' }
    let(:form_data) { fixture_as_json 'valid_200995.json', version: 'v2' }

    it { expect(sc_with_nvc.stamp_text).to eq 'Doé - 6789' }

    it 'truncates the last name if too long' do
      full_last_name = 'AAAAAAAAAAbbbbbbbbbbCCCCCCCCCCdddddddddd'
      default_auth_headers['X-VA-Last-Name'] = full_last_name

      sc = AppealsApi::SupplementalClaim.new(auth_headers: default_auth_headers, form_data: form_data)

      expect(sc.stamp_text).to eq 'AAAAAAAAAAbbbbbbbbbbCCCCCCCCCCdd... - 6789'
    end
  end

  describe '#lob' do
    it { expect(sc_with_nvc.lob).to eq 'CMP' }
  end

  context 'appellant handling' do
    describe '#veteran' do
      subject { sc_with_nvc.veteran }

      it { expect(subject.class).to eq AppealsApi::Appellant }
    end

    describe '#claimant' do
      subject { sc_with_nvc.claimant }

      it { expect(subject.class).to eq AppealsApi::Appellant }
    end

    context 'when veteran only data' do
      describe '#signing_appellant' do
        let(:appellant_type) { supplemental_claim_veteran_only.signing_appellant.send(:type) }

        it { expect(appellant_type).to eq :veteran }
      end

      describe '#appellant_local_time' do
        it do
          appellant_local_time = supplemental_claim_veteran_only.appellant_local_time
          created_at = supplemental_claim_veteran_only.created_at

          expect(appellant_local_time).to eq created_at.in_time_zone('America/Chicago')
        end
      end

      describe '#full_name' do
        it { expect(supplemental_claim_veteran_only.full_name).to eq 'Jäñe ø Doé' }
      end

      describe '#signing_appellant_zip_code' do
        it { expect(supplemental_claim_veteran_only.signing_appellant_zip_code).to eq '30012' }
      end
    end

    context 'when veteran and claimant data' do
      describe '#signing_appellant' do
        let(:appellant_type) { sc_with_nvc.signing_appellant.send(:type) }

        it { expect(appellant_type).to eq :claimant }
      end

      describe '#appellant_local_time' do
        it do
          appellant_local_time = sc_with_nvc.appellant_local_time
          created_at = sc_with_nvc.created_at

          expect(appellant_local_time).to eq created_at.in_time_zone('America/Detroit')
        end
      end

      describe '#full_name' do
        it { expect(sc_with_nvc.full_name).to eq 'joe b smart' }
      end

      describe '#signing_appellant_zip_code' do
        it { expect(sc_with_nvc.signing_appellant_zip_code).to eq '00000' }
      end
    end

    describe '#stamp_text' do
      let(:supplemental_claim) { build(:supplemental_claim) }

      it { expect(supplemental_claim.stamp_text).to eq('Doé - 6789') }

      it 'truncates the last name if too long' do
        full_last_name = 'AAAAAAAAAAbbbbbbbbbbCCCCCCCCCCdddddddddd'
        supplemental_claim.auth_headers['X-VA-Last-Name'] = full_last_name
        expect(supplemental_claim.stamp_text).to eq 'AAAAAAAAAAbbbbbbbbbbCCCCCCCCCCdd... - 6789'
      end
    end
  end
end
