# frozen_string_literal: true

class AppealsApi::MonthlyStatsReport
  include Sidekiq::Worker
  include Sidekiq::MonitoredWorker

  sidekiq_options retry: 20, unique_for: 3.weeks

  def perform(end_date: Time.zone.now)
    return unless enabled?

    recipients = Settings.modules_appeals_api.reports.monthly_stats&.recipients || []
    return if recipients.empty?

    date_to = end_date.beginning_of_day
    date_from = (date_to - 1.month).beginning_of_day

    AppealsApi::StatsReportMailer.build(
      date_from: date_from,
      date_to: date_to,
      recipients: recipients,
      subject: "Lighthouse appeals stats report for month starting #{date_from.strftime('%Y-%m-%d')}"
    ).deliver_now
  end

  private

  def enabled?
    FeatureFlipper.send_email? && Flipper.enabled?(:decision_review_monthly_stats_report_enabled)
  end
end
