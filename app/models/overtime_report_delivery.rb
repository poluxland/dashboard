class OvertimeReportDelivery < ApplicationRecord
  RETRY_WINDOW = 2.hours

  def self.dispatch_due(reference_time: Time.current, start_at: ENV["OVERTIME_REPORT_START_AT"])
    return if start_at.blank?

    date = reference_time.utc.to_date
    scheduled_at = Time.utc(date.year, date.month, date.day, 11, 30)
    return unless scheduled_at >= Time.iso8601(start_at)
    return unless (scheduled_at...(scheduled_at + RETRY_WINDOW)).cover?(reference_time)

    OvertimeAccess::RECIPIENTS.each do |email|
      begin
        find_or_create_by!(scheduled_at: scheduled_at, recipient: email).deliver!
      rescue StandardError => error
        Rails.logger.error("Overtime pending report failed: #{error.class}")
      end
    end
  end

  def deliver!
    with_lock do
      return if sent_at?

      OvertimeMailer.pending_report(recipient: recipient).deliver_now
      update!(sent_at: Time.current)
    end
  end
end
