class HaverDailyDelivery < ApplicationRecord
  RETRY_WINDOW = 2.hours

  def self.dispatch_due(reference_time: Time.current)
    date = reference_time.in_time_zone(HaverDailyReport::CHILE).to_date
    return unless (1..5).cover?(date.cwday)

    scheduled_at = HaverDailyReport.cutoff_for(date)
    return unless (scheduled_at...(scheduled_at + RETRY_WINDOW)).cover?(reference_time)

    find_or_create_by!(scheduled_on: date).deliver!
  end

  def deliver!
    with_lock do
      return if sent_at?

      HaverDailyMailer.report(scheduled_at: HaverDailyReport.cutoff_for(scheduled_on)).deliver_now
      update!(sent_at: Time.current)
      sent_at
    end
  end
end
