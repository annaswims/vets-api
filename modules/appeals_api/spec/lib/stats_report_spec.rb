# frozen_string_literal: true

require 'rails_helper'
require 'appeals_api/stats_report'

describe AppealsApi::StatsReport do
  let(:end_date) { DateTime.new(2022, 3, 4, 5, 6, 7) }
  let(:start_date) { end_date - 1.month }
  let(:report) { described_class.new(start_date, end_date) }

  let!(:inside_range) do
    [
      create(:higher_level_review_v2),
      create(:notice_of_disagreement_v2),
      create(:supplemental_claim),
      create(:supplemental_claim)
    ]
  end
  let!(:outside_range) do
    create(:higher_level_review_v2)
  end
  let!(:wrong_status) do
    [
      create(:higher_level_review_v2),
      create(:notice_of_disagreement_v2),
      create(:supplemental_claim)
    ]
  end
  let(:status_from) { 'submitted' }
  let(:status_to) { 'complete' }

  before do
    Sidekiq::Testing.inline! do
      # These records should be included:
      Timecop.freeze(start_date - 1.week)
      inside_range.each { |r| r.update_status!(status: status_from) }
      Timecop.travel(start_date)
      # Make most of the status transitions around the same timespan:
      inside_range[0..2].each_with_index do |r, n|
        Timecop.travel(start_date + n.days)
        r.update_status!(status: status_to)
      end
      # But make one timespan longer to throw off the mean:
      Timecop.travel(end_date - 1.day)
      inside_range[3].update_status(status: status_to)

      # These records should not be included:
      Timecop.travel(start_date - 1.week)
      outside_range.update_status!(status: status_from)
      Timecop.travel(start_date - 1.day)
      outside_range.update_status!(status: status_to)

      Timecop.travel(end_date - 1.week)
      wrong_status[0].update_status!(status: status_to)
      wrong_status[1].update_status!(status: status_from)
      wrong_status[2].update_status!(status: 'complete')
      Timecop.travel(end_date - 1.day)
      wrong_status[0].update_status!(status: status_from)
      wrong_status[1].update_status!(status: 'error')
      wrong_status[2].update_status!(status: status_to)
    end
  end

  after do
    Timecop.return
  end

  describe '#status_update_records' do
    it "finds pairs of updates that match the given from/to statuses and end within the report's timespan" do
      status_update_pairs = report.send(:status_update_records, status_from, status_to)
      start_statuses, end_statuses = status_update_pairs.transpose
      expect(start_statuses.pluck(:statusable_id)).to match_array(inside_range.pluck(:id))
      expect(start_statuses.pluck(:statusable_id)).to match_array(end_statuses.pluck(:statusable_id))
      expect(start_statuses.pluck(:from)).to all(eq(status_from))
      expect(start_statuses.pluck(:to)).to all(eq(status_to))
    end
  end

  describe '#stats' do
    it 'finds the mean and median timespan between the given pairs of status update records' do
      result = report.send(:stats, report.send(:status_update_records, status_from, status_to))
      expect(result[:mean]).to eq(1_252_800)
      expect(result[:median]).to eq(734_400)
    end

    it 'returns nil data when no status update pairs are given' do
      result = report.send(:stats, [])
      expect(result[:mean]).to be_nil
      expect(result[:median]).to be_nil
    end
  end

  describe '#text' do
    let(:text) { report.text }

    it 'includes the start and end dates' do
      expect(text).to match(/Feb 4, 2022 to Mar 4, 2022/)
    end

    it 'includes stats for status transitions where data was found' do
      expect(text).to match(/From 'submitted' to 'complete':\n\n\* Average: 14d 12h 0m\n\* Median:  8d 12h 0m/)
    end

    it 'includes empty states for status transitions where no data was found' do
      expect(text).to match(/From 'processing' to 'success':\n\n\* Average: \(none\)\n\* Median:  \(none\)/)
    end
  end
end
