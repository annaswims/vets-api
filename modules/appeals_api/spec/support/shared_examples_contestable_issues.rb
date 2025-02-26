# frozen_string_literal: true

require AppealsApi::Engine.root.join('spec', 'spec_helper.rb')

RSpec.shared_examples 'contestable issues index requests' do |options|
  describe '#index' do
    context 'when using SSN header as veteran identifier' do
      it 'GETs contestable_issues from Caseflow successfully' do
        VCR.use_cassette("caseflow/#{options[:decision_review_type]}/contestable_issues") do
          get_issues(ssn: '872958715', file_number: nil, options: options)
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['data']).not_to be nil
        end
      end
    end

    context 'when using file_number header as veteran identifier' do
      it 'GETs contestable_issues from Caseflow successfully' do
        VCR.use_cassette("caseflow/#{options[:decision_review_type]}/contestable_issues-by-file-number") do
          get_issues(file_number: '123456789', ssn: nil, options: options)
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['data']).not_to be nil
        end
      end
    end

    context 'when X-VA-Receipt-Date is missing' do
      it 'returns a 422' do
        get_issues(ssn: '872958715', receipt_date: nil, options: options)
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_an Array
      end
    end

    if options[:benefit_type].present?
      context 'when benefit_type is unknown' do
        it 'returns a 422' do
          tmp_options = options.dup
          tmp_options[:benefit_type] = 'invalid benefit type'
          get_issues(ssn: '872958715', options: tmp_options)
          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json['errors']).to be_an Array
        end
      end
    end

    context 'when X-VA-SSN and X-VA-File-Number are missing' do
      it 'returns a 422' do
        get_issues(ssn: nil, file_number: nil, options: options)
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_an Array
      end
    end

    context 'when X-VA-SSN has an invalid format' do
      it 'returns a 422' do
        get_issues(ssn: '87295a71b', options: options)
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_an Array
      end
    end

    context 'unusable response' do
      before do
        allow_any_instance_of(Caseflow::Service).to(
          receive(:get_contestable_issues).and_return(
            Struct.new(:status, :body).new(
              200,
              '<html>Some html!</html>'
            )
          )
        )
      end

      it 'logs the error response' do
        expect_any_instance_of(described_class).to receive(:log_caseflow_error)
          .with('UnusableResponse', 200, '<html>Some html!</html>')
        get_issues(options: options)
      end

      it 'returns a 502 when Caseflow returns an unusable response' do
        get_issues(options: options)
        expect(response).to have_http_status(:bad_gateway)
        expect(JSON.parse(response.body)['errors']).to be_an Array
      end
    end

    context 'Caseflow 4XX response' do
      let(:status) { 400 }
      let(:body) { { hello: 'world' }.as_json }

      before do
        allow_any_instance_of(Caseflow::Service).to(
          receive(:get_contestable_issues).and_return(
            Struct.new(:status, :body).new(status, body)
          )
        )
      end

      it 'lets 4XX responses passthrough' do
        get_issues(options: options)
        expect(response.status).to be status
        expect(JSON.parse(response.body)).to eq body
      end
    end

    context 'Caseflow raises BackendServiceException' do
      before do
        allow_any_instance_of(Caseflow::Service).to(
          receive(:get_contestable_issues).and_raise(
            Common::Exceptions::BackendServiceException.new(nil, {}, 503, 'Timeout')
          )
        )
      end

      it 'logs the error' do
        expect_any_instance_of(described_class).to receive(:log_caseflow_error)
          .with('BackendServiceException', 503, 'Timeout')
        get_issues(options: options)
      end
    end
  end

  private

  def get_headers(ssn: '872958715', file_number: nil, receipt_date: '2019-12-01')
    headers = {}

    headers['X-VA-Receipt-Date'] = receipt_date if receipt_date.present?
    if file_number.present?
      headers['X-VA-File-Number'] = file_number
    elsif ssn.present?
      headers['X-VA-SSN'] = ssn
    end

    headers
  end

  def get_path(options)
    if options[:version] == 'v2'
      (
        if options[:use_versioned_namespace_route]
          '/services/appeals/contestable_issues/v0/contestable_issues'
        else
          '/services/appeals/v2/decision_reviews/contestable_issues'
        end
      ) + "/#{options[:decision_review_type]}?benefit_type=#{options[:benefit_type]}"
    else
      "/services/appeals/v1/decision_reviews/#{options[:decision_review_type]}/" \
        "contestable_issues/#{options[:benefit_type]}"
    end
  end

  def get_issues(options:, **headers_kwargs)
    headers = get_headers(**headers_kwargs)
    path = get_path(options)

    if options[:use_versioned_namespace_route]
      with_openid_auth(%w[claim.read]) do |auth_header|
        get(path, headers: headers.merge(auth_header))
      end
    else
      get(path, headers: headers)
    end
  end
end
