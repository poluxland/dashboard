class PmmTruckReportDelivery < ApplicationRecord
  RETRY_WINDOW = 2.hours

  def self.dispatch_due(reference_time: Time.current, start_at: ENV["PMM_TRUCK_REPORT_START_AT"],
                        utc_times: ENV["PMM_TRUCK_REPORT_UTC_TIMES"], days: ENV.fetch("PMM_TRUCK_REPORT_DAYS", "1,2,3,4,5,6,7"))
    return if start_at.blank? || utc_times.blank?

    enabled_from = Time.iso8601(start_at)
    date = reference_time.utc.to_date
    weekdays = days.split(",").map(&:to_i)
    times = utc_times.split(",").map do |time|
      raise ArgumentError, "Hora inválida" unless time.match?(/\A(?:[01]\d|2[0-3]):[0-5]\d\z/)

      time.split(":").map(&:to_i)
    end
    [ date.yesterday, date ].each do |day|
      next unless weekdays.include?(day.cwday)

      times.each do |hour, minute|
        scheduled_at = Time.utc(day.year, day.month, day.day, hour, minute)
        next unless scheduled_at >= enabled_from && (scheduled_at...(scheduled_at + RETRY_WINDOW)).cover?(reference_time)

        find_or_create_by!(scheduled_at: scheduled_at).deliver!
      end
    end
  end

  def deliver!
    with_lock do
      return if sent_at?

      PmmTruckMailer.report(scheduled_at: scheduled_at).deliver_now
      update!(sent_at: Time.current)
    end
  end
end
