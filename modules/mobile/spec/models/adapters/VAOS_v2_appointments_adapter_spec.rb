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
    expect(adapted_appointments.size).to eq(1)
  end

  context 'with a cancelled VA appointment' do
    let(:cancelled_va) { adapted_appointments[0] }

    it 'has an id' do
      expect(cancelled_va[:id]).to eq('121133')
    end

    it 'has a cancel id of the encoded cancel params' do
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
      expect(cancelled_va[:minutes_duration]).to eq('30')
    end

    it 'has a utc start date' do
      expect(cancelled_va[:start_date_utc]).to eq(DateTime.parse('Sat, 27 Aug 2022 15:45:00 +0000'))
    end

    it 'has a local start date' do
      expect(cancelled_va[:start_date_local]).to eq(DateTime.parse('Sat, 27 Aug 2022 09:45:00.000000000 MDT -06:00'))
    end

    it 'has a booked status' do
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

    it 'has a nil duration' do
      expect(booked_va[:minutes_duration]).to eq(30)
    end

    it 'has a utc start date' do
      expect(booked_va[:start_date_utc]).to eq(DateTime.parse('Wed, 07 Mar 2018 15:00:00 +0000'))
    end

    it 'has a local start date' do
      expect(booked_va[:start_date_local]).to eq(DateTime.parse('Wed, 07 Mar 2018 08:00:00.000000000 MST -07:00'))
    end

    it 'has a cancelled status' do
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
  end
end
