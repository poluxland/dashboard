class OvertimeReportDelivery < ApplicationRecord
  RETRY_WINDOW = 2.hours

  def self.dispatch_due(reference_time: Time.current, start_at: ENV["OVERTIME_REPORT_START_AT"])
    return if start_at.blank?

    date = reference_time.utc.to_date
    scheduled_at = Time.utc(date.year, date.month, date.day, 11, 30)
    return unless scheduled_at >= Time.iso8601(start_at)
    return unless (scheduled_at...(scheduled_at + RETRY_WINDOW)).cover?(reference_time)

    recipients = OvertimeAccess::RECIPIENTS
    transaction do
      deliveries = where(scheduled_at: scheduled_at, recipient: recipients)
      insert_all(recipients.map { |recipient| { scheduled_at: scheduled_at, recipient: recipient } }, unique_by: %i[scheduled_at recipient])
      next if deliveries.order(:id).lock.any?(&:sent_at?)

      OvertimeMailer.pending_report.deliver_now
      deliveries.update_all(sent_at: Time.current)
    end
  end
end
