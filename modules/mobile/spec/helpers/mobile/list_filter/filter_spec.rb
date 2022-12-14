# frozen_string_literal: true

require 'rails_helper'

class Pet < Common::Base
  attribute :species, String
  attribute :name, String
  attribute :age, Integer
end

describe Mobile::ListFilter::Filter do
  let(:fido) do
    Pet.new(species: 'dog', name: 'Fido', age: 5)
  end
  let(:rex) do
    Pet.new(species: 'dog', name: 'Rex', age: 2)
  end
  let(:cat) do
    Pet.new(species: 'cat', name: 'Purrsival', age: 12)
  end
  let(:list) do
    Common::Collection.new(data: [fido, rex, cat])
  end

  describe '.matches' do
    describe 'eq operator' do
      it 'finds matches' do
        filters = { species: { eq: 'dog' } }
        results = Mobile::ListFilter::Filter.matches(list, filters)
        expect(results.data).to eq([fido, rex])
      end
    end

    describe 'notEq operator' do
      it 'excludes non-matches' do
        filters = { species: { notEq: 'dog' } }
        results = Mobile::ListFilter::Filter.matches(list, filters)
        expect(results.data).to eq([cat])
      end
    end
  end

  it 'handles multiple filters' do
    filters = { species: { eq: 'dog' }, age: { notEq: 5 } }
    results = Mobile::ListFilter::Filter.matches(list, filters)
    expect(results.data).to eq([rex])
  end
end
