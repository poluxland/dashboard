class AprWeeklyDelivery < ApplicationRecord
  SEND_HOUR = 8

  def self.dispatch_due(reference_time: Time.current, recipients: ENV.fetch("APR_WEEKLY_REPORT_RECIPIENTS", ""))
    local_time = reference_time.in_time_zone(AprDay::ZONE)
    return unless local_time.monday? && local_time.hour >= SEND_HOUR

    addresses = recipients.downcase.split(/[\s,;]+/).select { |email| email.match?(URI::MailTo::EMAIL_REGEXP) }.uniq
    return if addresses.empty?

    find_or_create_by!(week_start: local_time.to_date - 7.days).deliver!(addresses)
  end

  def deliver!(addresses)
    with_lock do
      return if sent_at?

      report = AprWeeklyReport.new(week_start)
      AprDayMailer.weekly_summary(report: report, recipients: addresses).deliver_now
      update!(sent_at: Time.current, recipients: addresses)
      sent_at
    end
  end
end
