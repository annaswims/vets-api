# frozen_string_literal: true

require 'rails_helper'
require 'mpi/messages/find_profile_message_with_address'

describe MPI::Messages::FindProfileMessageWithAddress do
  describe '.to_xml' do
    context 'with first, last, birth_date, and ssn from auth provider' do
      let(:xml) do
        described_class.new(
          address: {
            'addressLine1' => '123 Main Street',
            'city' => 'New York',
            'stateCode' => 'NY',
            'zipCode5' => '30012',
            'countryCodeISO2' => 'US'
          },
          given_names: %w[John William],
          last_name: 'Smith',
          birth_date: '1980-1-1',
          gender: 'M'
        ).to_xml
      end
      let(:idm_path) { 'env:Body/idm:PRPA_IN201305UV02' }
      let(:parameter_list_path) { "#{idm_path}/controlActProcess/queryByParameter/parameterList" }

      it 'has a USDSVA extension with a uuid' do
        expect(xml).to match_at_path("#{idm_path}/id/@extension", /200VGOV-\w{8}-\w{4}-\w{4}-\w{4}-\w{12}/)
      end

      it 'has a sender extension' do
        expect(xml).to eq_at_path("#{idm_path}/sender/device/id/@extension", '200VGOV')
      end

      it 'has a receiver extension' do
        expect(xml).to eq_at_path("#{idm_path}/receiver/device/id/@extension", '200M')
      end

      it 'has the correct query parameter order' do
        parsed_xml = Ox.parse(xml)
        nodes = parsed_xml.locate(parameter_list_path).first.nodes
        expect(nodes[0].value).to eq('livingSubjectAdministrativeGender')
        expect(nodes[1].value).to eq('livingSubjectBirthTime')
        expect(nodes[2].value).to eq('livingSubjectName')
        expect(nodes[3].value).to eq('PatientAddress')
      end

      it 'has a name node' do
        expect(xml).to eq_text_at_path("#{parameter_list_path}/livingSubjectName/value/given[0]", 'John')
        expect(xml).to eq_text_at_path("#{parameter_list_path}/livingSubjectName/value/given[1]", 'William')
        expect(xml).to eq_text_at_path("#{parameter_list_path}/livingSubjectName/value/family", 'Smith')
        expect(xml).to eq_text_at_path("#{parameter_list_path}/livingSubjectName/semanticsText", 'Legal Name')
      end

      it 'has a birth time node' do
        expect(xml).to eq_at_path("#{parameter_list_path}/livingSubjectBirthTime/value/@value", '19800101')
        expect(xml).to eq_text_at_path("#{parameter_list_path}/livingSubjectBirthTime/semanticsText", 'Date of Birth')
      end

      it 'has a gender node' do
        expect(xml).to eq_at_path("#{parameter_list_path}/livingSubjectAdministrativeGender/value/@code", 'M')
        expect(xml).to eq_text_at_path(
          "#{parameter_list_path}/livingSubjectAdministrativeGender/semanticsText",
          'Gender'
        )
      end
    end

    context 'with nil gender' do
      let(:xml) do
        MPI::Messages::FindProfileMessageWithAddress.new(
          address: {
            'addressLine1' => '123 Main Street',
            'city' => 'New York',
            'stateCode' => 'NY',
            'zipCode5' => '30012',
            'countryCodeISO2' => 'US'
          },
          given_names: %w[John William],
          last_name: 'Smith',
          birth_date: '1980-1-1',
          gender: nil
        ).to_xml
      end
      let(:idm_path) { 'env:Body/idm:PRPA_IN201305UV02' }
      let(:parameter_list_path) { "#{idm_path}/controlActProcess/queryByParameter/parameterList" }

      it 'does not have a gender node' do
        expect(xml).to eq_at_path("#{parameter_list_path}/livingSubjectAdministrativeGender/value/@code", nil)
      end

      it 'has the correct query parameter order' do
        parsed_xml = Ox.parse(xml)
        nodes = parsed_xml.locate(parameter_list_path).first.nodes
        expect(nodes[0].value).to eq('livingSubjectBirthTime')
        expect(nodes[1].value).to eq('livingSubjectName')
        expect(nodes[2].value).to eq('PatientAddress')
      end
    end

    context 'missing arguments' do
      let(:address_missing_key) { { addressLine1: '123 Main Street', zipCode5: '12345', countryCodeISO2: 'US' } }
      let(:address_empty_value) do
        { addressLine1: '123 Main Street', city: '', zipCode5: '12345', countryCodeISO2: 'US' }
      end
      let(:address_nil_values) { { addressLine1: '123 Main Street', city: nil, zipCode5: nil, countryCodeISO2: 'US' } }

      it 'throws an argument error for missing key' do
        expect do
          MPI::Messages::FindProfileMessageWithAddress.new(
            given_names: %w[John William],
            last_name: 'Smith',
            birth_date: Time.new(1980, 1, 1).utc,
            address: address_missing_key
          )
        end.to raise_error(ArgumentError, 'required keys are missing: [:city]')
      end

      it 'throws an argument error for empty value' do
        expect do
          MPI::Messages::FindProfileMessageWithAddress.new(
            given_names: %w[John William],
            last_name: 'Smith',
            birth_date: Time.new(1980, 1, 1).utc,
            address: address_empty_value
          )
        end.to raise_error(ArgumentError, 'required values are missing for keys: [:city]')
      end

      it 'throws an argument error for nil value' do
        expect do
          MPI::Messages::FindProfileMessageWithAddress.new(
            given_names: %w[John William],
            last_name: nil,
            birth_date: Time.new(1980, 1, 1).utc,
            address: address_nil_values
          )
        end.to raise_error(ArgumentError, 'required values are missing for keys: [:last_name, :city, :zipCode5]')
      end
    end
  end

  describe '#required_fields_present?' do
    subject { described_class.new(profile) }

    let(:missing_keys) { ':given_names, :last_name, :birth_date, :address' }

    context 'missing keys' do
      let(:profile) { {} }

      it 'raises with list of missing keys' do
        expect { subject }.to raise_error(/#{missing_keys}/)
      end
    end

    context 'missing values' do
      let(:empty_address) { { addressLine1: '', city: '', zipCode5: '', countryCodeISO2: '' } }
      let(:profile) { { given_names: nil, last_name: '', birth_date: nil, address: empty_address } }

      it 'raises with list of keys for missing values' do
        expect { subject }.to raise_error(/#{missing_keys}/)
      end
    end
  end
end
