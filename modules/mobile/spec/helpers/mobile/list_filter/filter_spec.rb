# frozen_string_literal: true

require 'rails_helper'

class TestModel < Common::Base
  attribute :type, String
  # attribute :active, Bool
  # attribute :created_at, DateTime
end

describe Mobile::ListFilter::Filter do
  let(:record) do
    TestModel.new(type: "dog")
  end

  let(:list) do
    Common::Collection.new(data: [record])
  end

  describe '.matches' do
    it 'finds matches' do
      filters = [{ type: { eq: 'dog' }}]
      results = Mobile::ListFilter::Filter.matches(list, filters)
      expect(results).to eq(list)
    end

    it 'works with collections'
    it 'works with arrays'
  end
end
