# frozen_string_literal: true

require 'rails_helper'

class TestModel < VAProfile::Models::Base
  attribute :effective_end_date, Common::ISO8601Time
end

describe Mobile::ListFilter::Filter do
  let(:record) do

  end
  let(:list) do

  end
  describe '.matches' do
    it 'finds matches' do
      subject.match()
    end
  end
end
