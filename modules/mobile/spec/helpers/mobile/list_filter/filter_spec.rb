# frozen_string_literal: true

require 'rails_helper'

class TestModel < VAProfile::Models::Base
  attribute :type, Types::String.optional
  attribute :active, Types::Bool.optional
  attribute :created_at, Types::DateTime
end

describe Mobile::ListFilter::Filter do
  let(:record) do
    TestModel.new(type: "dog")
  end

  let(:list) do
    Common::Collection.new([record])
  end

  describe '.matches' do
    it 'finds matches' do
      filters = { type: { eq: 'dog' }}
      results = subject.match(list, filters)
      expect(results).to eq(list)
    end
  end
end
