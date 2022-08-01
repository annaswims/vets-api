# frozen_string_literal: true

require 'rails_helper'
require_relative '../support/iam_session_helper'
require_relative '../support/matchers/json_schema_matcher'

RSpec.describe 'appointments', type: :request do
  include JsonSchemaMatchers

  mock_clinic = {
    'service_name': 'service_name',
    'physical_location': 'physical_location'
  }

  mock_clinic_without_physical_location = {
    'service_name': 'service_name'
  }

  mock_facility = {
    "id":"983",
    "vistaSite":"983",
    "vastParent":"983",
    "type":"va_facilities",
    "name":"Cheyenne VA Medical Center",
    "classification":"VA Medical Center (VAMC)",
    "lat":39.744507,
    "long":-104.830956,
    "website":"https://www.denver.va.gov/locations/directions.asp",
    "phone":{
      "main":"307-778-7550",
      "fax":"307-778-7381",
      "pharmacy":"866-420-6337",
      "afterHours":"307-778-7550",
      "patientAdvocate":"307-778-7550 x7517",
      "mentalHealthClinic":"307-778-7349",
      "enrollmentCoordinator":"307-778-7550 x7579"
    },
    "physicalAddress":{
      "type":"physical",
      "line":[
        "2360 East Pershing Boulevard"
      ],
      "city":"Cheyenne",
      "state":"WY",
      "postalCode":"82001-5356"
    },
    "mobile":false,
    "healthService":[
      "Audiology",
      "Cardiology",
      "DentalServices",
      "EmergencyCare",
      "Gastroenterology",
      "Gynecology",
      "MentalHealthCare",
      "Nutrition",
      "Ophthalmology",
      "Optometry",
      "Orthopedics",
      "Podiatry",
      "PrimaryCare",
      "SpecialtyCare",
      "UrgentCare",
      "Urology",
      "WomensHealth"
    ],
    "operatingStatus":{
      "code":"NORMAL"
    }
  }

  mock_provider = { "providerIdentifier": '1407938061', "providerIdentifierType": 'NPI', "name": "DEHGHAN,
        AMIR ", "providerType": 'Individual', "email": 'DRDEHGHAN@COMCAST.NET', "providerStatusReason": 'Active', "primaryCarePhysician": false, "isAcceptingNewPatients": true, "providerGender": 'Male', "isExternal": true, "canCreateHealthCareOrders": false, "contactMethodEmail": false, "contactMethodFax": false, "contactMethodVirtuPro": false, "contactMethodHSRM": false, "contactMethodPhone": false, "contactMethodMail": false, "contactMethodRefDoc": false, "bulkEmails": false, "bulkMails": true, "emails": false, "mails": false, "phoneCalls": false, "faxes": false, "preferredMeansReceivingReferralHSRM": false, "preferredMeansReceivingReferralSecuredEmail": false, "preferredMeansReceivingReferralMail": false, "preferredMeansReceivingReferralFax": false, "modifiedOnDate": '2021-08-26T21:03:42Z' }

  before do
    iam_sign_in(build(:iam_user))
    allow_any_instance_of(IAMUser).to receive(:icn).and_return('1012846043V576341')
    allow_any_instance_of(VAOS::UserService).to receive(:session).and_return('stubbed_token')
    Flipper.enable(:mobile_appointment_requests)
    Flipper.enable(:mobile_appointment_use_VAOS_MFS)
    Flipper.enable(:mobile_appointment_use_VAOS_v2)
    allow_any_instance_of(Mobile::V0::Appointments::Proxy).to receive(:get_clinic).and_return(mock_clinic)
    allow_any_instance_of(Mobile::V0::Appointments::Proxy).to receive(:get_facility).and_return(mock_facility)
    allow_any_instance_of(Mobile::V0::Appointments::Proxy).to receive(:get_provider).and_return(mock_provider)
  end

  before(:all) do
    @original_cassette_dir = VCR.configure(&:cassette_library_dir)
    VCR.configure { |c| c.cassette_library_dir = 'modules/mobile/spec/support/vcr_cassettes' }
  end

  after(:all) { VCR.configure { |c| c.cassette_library_dir = @original_cassette_dir } }

  describe 'GET /mobile/v0/appointments' do
    before do
      Timecop.freeze(Time.zone.parse('2022-01-01T19:25:00Z'))
    end

    after { Timecop.return }

    let(:start_date) { Time.zone.parse('2019-01-01T19:25:00Z').iso8601 }
    let(:end_date) { Time.zone.parse('2023-12-01T19:45:00Z').iso8601 }
    let(:params) { { startDate: start_date, endDate: end_date } }

    context 'requests a list of appointments' do
      it 'has access and returns va appointments and honors includes' do
        VCR.use_cassette('appointments/VAOS_v2/get_appointments_200', match_requests_on: %i[method uri]) do
          get '/mobile/v0/appointments', headers: iam_headers, params: params
        end

        binding.pry
        data = JSON.parse(response.body)['data']
        expect(response).to have_http_status(:ok)
        expect(response.body).to be_a(String)
        expect(data.size).to eq(23)
        expect(data[0]['attributes']['serviceName']).to eq('service_name')
        expect(data[0]['attributes']['physicalLocation']).to eq('physical_location')
        expect(data[0]['attributes']['location']).to eq(mock_facility)
        expect(response).to match_camelized_response_schema('vaos/v2/appointments', { strict: false })
      end
    end
  end
end
