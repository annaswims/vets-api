# frozen_string_literal: true

module DebtManagementCenter
  class DebtsConfiguration
    extend Forwardable

    def initialize(use_mock: false)
      @use_mock = use_mock
    end

    def base_request_headers
      {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'client_id' => Settings.dmc.client_id,
        'client_secret' => Settings.dmc.client_secret
      }
    end

    def request_options
      {
        open_timeout: 15,
        read_timeout: 15
      }
    end

    def service_name
      'Debts'
    end

    def base_path
      Settings.dmc.url
    end

    delegate :post, to: :connection

    private

    def connection
      Faraday.new(base_path, headers: base_request_headers, request: request_options) do |f|
        f.use :breakers
        f.use Faraday::Response::RaiseError
        f.request :json
        f.response :betamocks if @use_mock
        f.response :json
        f.adapter Faraday.default_adapter
      end
    end
  end
end
