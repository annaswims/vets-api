# frozen_string_literal: true

module AppealsApi
  class StatsReport
    DATE_FORMAT = '%b%e, %Y'

    STATUS_TRANSITION_PAIRS = [
      %w[processing submitted], %w[submitted complete], %w[processing success], %w[error success]
    ]

    def initialize(date_from, date_to)
      @date_from = date_from.to_date
      @date_to = date_to.to_date
    end

    def text
      <<~REPORT
        Appeals stats report
        #{date_from.strftime(DATE_FORMAT)} to #{date_to.strftime(DATE_FORMAT)}
        ===

        Higher Level Reviews
        ---
        #{formatted_stats(AppealsApi::HigherLevelReview)}

        Notice of Disagreements
        ---
        #{formatted_stats(AppealsApi::NoticeOfDisagreement)}

        Supplemental Claims
        ---
        #{formatted_stats(AppealsApi::SupplementalClaim)}
      REPORT
    end

    private

    attr_accessor :date_from, :date_to

    def status_update_records(statusable_type, status_from, status_to)
      @records ||= {}
      @records[statusable_type] ||= {}
      @records[statusable_type][status_from] ||= {}
      @records[statusable_type][status_from][status_to] ||=
        begin
          records = AppealsApi::StatusUpdate.where(
            from: status_from,
            to: status_to,
            statusable_type: statusable_type,
            status_update_time: date_from..date_to
          ).order(:statusable_id)
          previous_records = AppealsApi::StatusUpdate.where(
            to: status_from,
            statusable_id: records.pluck(:statusable_id),
            statusable_type: statusable_type
          ).order(:statusable_id)
          records.zip(previous_records)
        end
    end

    def stats(update_record_pairs)
      return { mean: nil, median: nil } if update_record_pairs.empty?

      sum, values = update_record_pairs.reduce([0, []]) do |(s, v), (current, previous)|
        timespan = current.status_update_time - previous.status_update_time
        [s + timespan, v << timespan]
      end

      values.sort!
      middle = (values.count - 1) / 2.0

      {
        mean: sum / values.count,
        median: (values[middle.floor] + values[middle.ceil]) / 2.0
      }
    end

    def timespan_in_words(seconds)
      return '(none)' if seconds.nil?

      minutes, = seconds.divmod(60)
      hours, minutes = minutes.divmod(60)
      days, hours = hours.divmod(24)

      "#{days}d #{hours}h #{minutes}m"
    end

    def formatted_stats(appeal_class)
      texts = %w[]

      STATUS_TRANSITION_PAIRS.each do |(status_from, status_to)|
        values = stats(status_update_records(appeal_class.name, status_from, status_to))

        texts << <<~STATS
          From '#{status_from}' to '#{status_to}':
          * Average: #{timespan_in_words(values[:mean])}
          * Median:  #{timespan_in_words(values[:median])}
        STATS
      end

      texts.join("\n")
    end
  end
end
