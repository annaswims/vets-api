# frozen_string_literal: true

require 'rails_helper'

class TestModel < Common::Base
  attribute :type, String
  # attribute :active, Bool
  # attribute :created_at, DateTime
end

describe Mobile::ListFilter::Filter do
  let(:dog) do
    TestModel.new(type: "dog")
  end
  let(:cat) do
    TestModel.new(type: "cat")
  end
  let(:list) do
    Common::Collection.new(data: [dog, cat])
  end

  describe '.matches' do
    describe 'eq operator' do
      it 'finds matches' do
        filters = { type: { eq: 'dog' }}
        results = Mobile::ListFilter::Filter.matches(list, filters)
        expect(results.data).to eq([dog])
      end
    end

    describe 'notEq operator' do
      it 'excludes non-matches' do
        filters = { type: { notEq: 'dog' }}
        results = Mobile::ListFilter::Filter.matches(list, filters)
        expect(results.data).to eq([cat])
      end
    end
  end
end
