class OperationWeeklyDelivery < ApplicationRecord
  def self.dispatch_due(reference_time: Time.current)
    local_time = reference_time.in_time_zone("America/Santiago")
    return unless local_time.monday? && local_time.hour >= 8

    dispatch_week(week_of: local_time.to_date - 1.week)
  end

  def self.dispatch_week(week_of:)
    recipients = ENV.fetch("OPERATIONS_REPORT_RECIPIENTS", "").split(/[\s,;]+/).reject(&:blank?).uniq
    return if recipients.empty?

    week_start = week_of.beginning_of_week(:monday)
    find_or_create_by!(week_start: week_start).deliver!(recipients: recipients)
  end

  def deliver!(recipients:)
    with_lock do
      return if sent_at?

      OperationActivityMailer.weekly_report(recipients: recipients, week_of: week_start).deliver_now
      update!(sent_at: Time.current)
      sent_at
    end
  end
end
