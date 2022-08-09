# frozen_string_literal: true

require 'rails_helper'

describe Mobile::V2::Adapters::Appointments do
  let(:appointment_fixtures) do
    File.read(Rails.root.join('modules', 'mobile', 'spec', 'support', 'fixtures', 'VAOS_v2_v2_appointment.json'))
  end

  let(:adapted_appointments) do
    subject.parse(JSON.parse(appointment_fixtures, symbolize_names: true))
  end

  it 'returns a list of appointments at the expected size' do
    expect(adapted_appointments.size).to eq(6)
  end

  context 'with a cancelled VA appointment' do
    let(:cancelled_va) { adapted_appointments[0] }

    it 'has an id' do
      expect(cancelled_va[:id]).to eq('121133')
    end

    it 'does not have a cancel id' do
      expect(cancelled_va[:cancel_id]).to eq(nil)
    end

    it 'has a type of VA' do
      expect(cancelled_va[:appointment_type]).to eq('VA')
    end

    it 'has a comment' do
      expect(cancelled_va[:comment]).to eq('This is a free form comment')
    end

    it 'has a healthcare_service that matches the clinic name' do
      expect(cancelled_va[:healthcare_service]).to eq('Friendly Name Optometry')
    end

    it 'has a location' do
      expect(cancelled_va[:location].to_h).to eq(
        {
          id: '442',
          name: 'Cheyenne VA Medical Center',
          address: {
            street: '2360 East Pershing Boulevard',
            city: 'Cheyenne',
            state: 'WY',
            zip_code: '82001-5356'
          },
          lat: 41.148026,
          long: -104.786255,
          phone: {
            area_code: '307',
            number: '778-7550',
            extension: nil
          },
          url: nil,
          code: nil
        }
      )
    end

    it 'has a duration' do
      expect(cancelled_va[:minutes_duration]).to eq(30)
    end

    it 'has a utc start date' do
      expect(cancelled_va[:start_date_utc]).to eq(DateTime.parse('Sat, 27 Aug 2022 15:45:00 +0000'))
    end

    it 'has a local start date' do
      expect(cancelled_va[:start_date_local]).to eq(DateTime.parse('Sat, 27 Aug 2022 09:45:00.000000000 MDT -06:00 '))
    end

    it 'has a cancelled status' do
      expect(cancelled_va[:status]).to eq('CANCELLED')
    end

    it 'has a time zone' do
      expect(cancelled_va[:time_zone]).to eq('America/Denver')
    end

    it 'has a vetext id' do
      expect(cancelled_va[:vetext_id]).to eq('999;20220827.090045')
    end

    it 'has a facility_id' do
      expect(cancelled_va[:facility_id]).to eq('442')
    end

    it 'has a sta6aid' do
      expect(cancelled_va[:sta6aid]).to eq('442')
    end

    it 'has a status detail' do
      expect(cancelled_va[:status_detail]).to eq('CANCELLED BY PATIENT')
    end

    it 'is not pending' do
      expect(cancelled_va[:is_pending]).to eq(false)
    end

    it 'is not phone only' do
      expect(cancelled_va[:phone_only]).to eq(false)
    end
  end

  context 'with a booked VA appointment' do
    let(:booked_va) { adapted_appointments[1] }

    it 'has an id' do
      expect(booked_va[:id]).to eq('121133')
    end

    it 'does not have a cancel id' do
      expect(booked_va[:cancel_id]).to be_nil
    end

    it 'has a type of VA' do
      expect(booked_va[:appointment_type]).to eq('VA')
    end

    it 'does not have comment' do
      expect(booked_va[:comment]).to be_nil
    end

    it 'has a healthcare_service that matches the clinic name' do
      expect(booked_va[:healthcare_service]).to eq('Friendly Name Optometry')
    end

    it 'has a location' do
      expect(booked_va[:location].to_h).to eq(
        {
          id: '442',
          name: 'Cheyenne VA Medical Center',
          address: {
            street: '2360 East Pershing Boulevard',
            city: 'Cheyenne',
            state: 'WY',
            zip_code: '82001-5356'
          },
          lat: 41.148026,
          long: -104.786255,
          phone: {
            area_code: '307',
            number: '778-7550',
            extension: nil
          },
          url: nil,
          code: nil
        }
      )
    end

    it 'has a duration' do
      expect(booked_va[:minutes_duration]).to eq(30)
    end

    it 'has a utc start date' do
      expect(booked_va[:start_date_utc]).to eq(DateTime.parse('Wed, 07 Mar 2018 15:00:00 +0000'))
    end

    it 'has a local start date' do
      expect(booked_va[:start_date_local]).to eq(DateTime.parse('Wed, 07 Mar 2018 08:00:00.000000000 MST -07:00'))
    end

    it 'has a booked status' do
      expect(booked_va[:status]).to eq('BOOKED')
    end

    it 'has a time zone' do
      expect(booked_va[:time_zone]).to eq('America/Denver')
    end

    it 'has a facility_id' do
      expect(booked_va[:facility_id]).to eq('442')
    end

    it 'has a sta6aid' do
      expect(booked_va[:sta6aid]).to eq('442')
    end

    it 'has no status detail' do
      expect(booked_va[:status_detail]).to be_nil
    end

    it 'is not pending' do
      expect(booked_va[:is_pending]).to eq(false)
    end

    it 'is not phone only' do
      expect(booked_va[:phone_only]).to eq(false)
    end
  end

  context 'with a booked CC appointment' do
    let(:booked_cc) { adapted_appointments[2] }

    it 'has an id' do
      expect(booked_cc[:id]).to eq('72106')
    end

    it 'does not have a cancel id' do
      expect(booked_cc[:cancel_id]).to eq('72106')
    end

    it 'has a type of VA' do
      expect(booked_cc[:appointment_type]).to eq('COMMUNITY_CARE')
    end

    it 'does not have comment' do
      expect(booked_cc[:comment]).to be_nil
    end

    it 'has a healthcare_service that matches the clinic name' do
      expect(booked_cc[:healthcare_service]).to eq('CC practice name')
    end

    it 'has a location' do
      expect(booked_cc[:location].to_h).to eq(
        {
          id: nil,
          name: 'CC practice name',
          address: {
            street: '1601 Needmore Rd Ste 1',
            city: 'Dayton',
            state: 'OH',
            zip_code: '45414'
          },
          lat: nil,
          long: nil,
          phone: {
            area_code: nil,
            number: nil,
            extension: nil
          },
          url: nil,
          code: nil
        }
      )
    end

    it 'has a duration' do
      expect(booked_cc[:minutes_duration]).to eq(60)
    end

    it 'has a utc start date' do
      expect(booked_cc[:start_date_utc]).to eq(DateTime.parse('Tue, 11 Jan 2022 15:00:00 +0000'))
    end

    it 'has a local start date' do
      expect(booked_cc[:start_date_local]).to eq(DateTime.parse('Tue, 11 Jan 2022 10:00:00.000000000 EST -05:00'))
    end

    it 'has a booked status' do
      expect(booked_cc[:status]).to eq('BOOKED')
    end

    it 'has a time zone' do
      expect(booked_cc[:time_zone]).to eq('America/New_York')
    end

    it 'has a facility_id' do
      expect(booked_cc[:facility_id]).to eq('552')
    end

    it 'has a sta6aid' do
      expect(booked_cc[:sta6aid]).to eq('552')
    end

    it 'has no status detail' do
      expect(booked_cc[:status_detail]).to be_nil
    end

    it 'is not pending' do
      expect(booked_cc[:is_pending]).to eq(false)
    end

    it 'has a friendly location name' do
      expect(booked_cc[:friendly_location_name]).to eq('CC practice name')
    end

    it 'has a type of care' do
      expect(booked_cc[:type_of_care]).to eq('primaryCare')
    end

    it 'is not phone only' do
      expect(booked_cc[:phone_only]).to eq(false)
    end
  end

  context 'with a proposed CC appointment' do
    let(:proposed_cc) { adapted_appointments[3] }

    it 'has an id' do
      expect(proposed_cc[:id]).to eq('72105')
    end

    it 'does have a cancel id' do
      expect(proposed_cc[:cancel_id]).to eq('72105')
    end

    it 'has a type of COMMUNITY_CARE' do
      expect(proposed_cc[:appointment_type]).to eq('COMMUNITY_CARE')
    end

    it 'does have a comment' do
      expect(proposed_cc[:comment]).to eq('this is a comment')
    end

    it 'has a nil healthcare_service' do
      expect(proposed_cc[:healthcare_service]).to be_nil
    end

    it 'has no location yet' do
      expect(proposed_cc[:location].to_h).to eq(
        {
          id: nil,
          name: nil,
          address: {
            street: nil,
            city: nil,
            state: nil,
            zip_code: nil
          },
          lat: nil,
          long: nil,
          phone: {
            area_code: nil,
            number: nil,
            extension: nil
          },
          url: nil,
          code: nil
        }
      )
    end

    it 'has a duration' do
      expect(proposed_cc[:minutes_duration]).to eq(60)
    end

    it 'has a utc start date' do
      expect(proposed_cc[:start_date_utc]).to eq(DateTime.parse('Wed, 26 Jan 2022 00:00:00 +0000 '))
    end

    it 'has a local start date' do
      expect(proposed_cc[:start_date_local]).to eq(DateTime.parse('Tue, 25 Jan 2022 19:00:00.000000000 EST -05:00'))
    end

    it 'has a submitted status' do
      expect(proposed_cc[:status]).to eq('SUBMITTED')
    end

    it 'has a time zone' do
      expect(proposed_cc[:time_zone]).to eq('America/New_York')
    end

    it 'has a facility_id' do
      expect(proposed_cc[:facility_id]).to eq('552')
    end

    it 'has a sta6aid' do
      expect(proposed_cc[:sta6aid]).to eq('552')
    end

    it 'has no status detail' do
      expect(proposed_cc[:status_detail]).to be_nil
    end

    it 'is pending' do
      expect(proposed_cc[:is_pending]).to eq(true)
    end

    it 'does not have a friendly location name' do
      expect(proposed_cc[:friendly_location_name]).to be_nil
    end

    it 'has a type of care' do
      expect(proposed_cc[:type_of_care]).to eq('primaryCare')
    end

    it 'is not phone only' do
      expect(proposed_cc[:phone_only]).to eq(false)
    end
  end

  context 'with a proposed VA appointment' do
    let(:proposed_va) { adapted_appointments[4] }

    it 'has an id' do
      expect(proposed_va[:id]).to eq('50956')
    end

    it 'has a cancel id' do
      expect(proposed_va[:cancel_id]).to eq('50956')
    end

    it 'has a type of VA' do
      expect(proposed_va[:appointment_type]).to eq('VA')
    end

    it 'does not have a comment' do
      expect(proposed_va[:comment]).to be_nil
    end

    it 'has healthcare_service' do
      expect(proposed_va[:healthcare_service]).to eq('Friendly Name Optometry')
    end

    it 'has a location' do
      expect(proposed_va[:location].to_h).to eq(
        {
          id: '442',
          name: 'Cheyenne VA Medical Center',
          address: {
            street: '2360 East Pershing Boulevard',
            city: 'Cheyenne',
            state: 'WY',
            zip_code: '82001-5356'
          },
          lat: 41.148026,
          long: -104.786255,
          phone: {
            area_code: '307',
            number: '778-7550',
            extension: nil
          },
          url: nil,
          code: nil
        }
      )
    end

    it 'has no duration' do
      expect(proposed_va[:minutes_duration]).to be_nil
    end

    it 'has a utc start date' do
      expect(proposed_va[:start_date_utc]).to eq(DateTime.parse('Tue, 28 Sep 2021 00:00:00 +0000'))
    end

    it 'has a local start date' do
      expect(proposed_va[:start_date_local]).to eq(DateTime.parse('Tue, 28 Sep 2021 00:00:00 +0000'))
    end

    it 'has a submitted status' do
      expect(proposed_va[:status]).to eq('SUBMITTED')
    end

    it 'has a time zone' do
      expect(proposed_va[:time_zone]).to eq('America/Denver')
    end

    it 'has a facility_id' do
      expect(proposed_va[:facility_id]).to eq('442')
    end

    it 'has a sta6aid' do
      expect(proposed_va[:sta6aid]).to eq('442')
    end

    it 'has no status detail' do
      expect(proposed_va[:status_detail]).to be_nil
    end

    it 'is pending' do
      expect(proposed_va[:is_pending]).to eq(true)
    end

    it 'does not have a friendly location name' do
      expect(proposed_va[:friendly_location_name]).to be_nil
    end

    it 'does not have a type of care' do
      expect(proposed_va[:type_of_care]).to be_nil
    end

    it 'is not phone only' do
      expect(proposed_va[:phone_only]).to eq(false)
    end
  end

  context 'with a phone VA appointment' do
    let(:phone_va) { adapted_appointments[5] }

    it 'has an id' do
      expect(phone_va[:id]).to eq('53352')
    end

    it 'has a cancel id of the encoded cancel params' do
      expect(phone_va[:cancel_id]).to eq('53352')
    end

    it 'has a type of VA' do
      expect(phone_va[:appointment_type]).to eq('VA')
    end

    it 'does not have a comment' do
      expect(phone_va[:comment]).to be_nil
    end

    it 'has a healthcare_service that matches the clinic name' do
      expect(phone_va[:healthcare_service]).to eq('Friendly Name Optometry')
    end

    it 'has a location' do
      expect(phone_va[:location].to_h).to eq(
        {
          id: '442',
          name: 'Cheyenne VA Medical Center',
          address: {
            street: '2360 East Pershing Boulevard',
            city: 'Cheyenne',
            state: 'WY',
            zip_code: '82001-5356'
          },
          lat: 41.148026,
          long: -104.786255,
          phone: {
            area_code: '307',
            number: '778-7550',
            extension: nil
          },
          url: nil,
          code: nil
        }
      )
    end

    it 'has no duration' do
      expect(phone_va[:minutes_duration]).to be_nil
    end

    it 'has a utc start date' do
      expect(phone_va[:start_date_utc]).to eq(DateTime.parse('Fri, 01 Oct 2021 12:00:00 +0000'))
    end

    it 'has a local start date' do
      expect(phone_va[:start_date_local]).to eq(DateTime.parse('Fri, 01 Oct 2021 12:00:00 +0000'))
    end

    it 'has a booked status' do
      expect(phone_va[:status]).to eq('SUBMITTED')
    end

    it 'has a time zone' do
      expect(phone_va[:time_zone]).to eq('America/Denver')
    end

    it 'has a vetext id' do
      expect(phone_va[:vetext_id]).to eq(';20211001.060000')
    end

    it 'has a facility_id' do
      expect(phone_va[:facility_id]).to eq('442')
    end

    it 'has a sta6aid' do
      expect(phone_va[:sta6aid]).to eq('442')
    end

    it 'has no status detail' do
      expect(phone_va[:status_detail]).to be_nil
    end

    it 'is pending' do
      expect(phone_va[:is_pending]).to eq(true)
    end

    it 'does not have a friendly location name' do
      expect(phone_va[:friendly_location_name]).to be_nil
    end

    it 'does not have a type of care' do
      expect(phone_va[:type_of_care]).to be_nil
    end

    it 'is phone only' do
      expect(phone_va[:phone_only]).to eq(true)
    end
  end
end
