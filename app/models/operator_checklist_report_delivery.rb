class OperatorChecklistReportDelivery < ApplicationRecord
  LCA_HOURS = [ 6, 14, 22 ].freeze
  RETRY_WINDOW = 2.hours

  def self.dispatch_due(reference_time: Time.current, start_at: ENV["OPERATOR_CHECKLIST_REPORT_START_AT"],
                        ptm_utc_time: ENV["OPERATOR_CHECKLIST_PTM_UTC_TIME"])
    return if start_at.blank?

    enabled_from = Time.iso8601(start_at)
    scheduled_slots(reference_time, ptm_utc_time).each do |plant, scheduled_at|
      next unless scheduled_at >= enabled_from && scheduled_at > reference_time - RETRY_WINDOW && scheduled_at <= reference_time

      begin
        find_or_create_by!(plant: plant, scheduled_at: scheduled_at).deliver!
      rescue StandardError => error
        Rails.logger.error("Operator checklist report #{plant} at #{scheduled_at.iso8601} failed: #{error.class}")
      end
    end
  end

  def self.scheduled_slots(reference_time, ptm_utc_time)
    local_date = reference_time.in_time_zone(OperatorChecklistReport::CHILE).to_date
    slots = [ local_date.yesterday, local_date ].flat_map do |date|
      LCA_HOURS.map do |hour|
        [ "LCA", OperatorChecklistReport::CHILE.local(date.year, date.month, date.day, hour) ]
      end
    end
    return slots if ptm_utc_time.blank?

    unless ptm_utc_time.match?(/\A(?:[01]\d|2[0-3]):[0-5]\d\z/)
      raise ArgumentError, "OPERATOR_CHECKLIST_PTM_UTC_TIME must use HH:MM in UTC"
    end

    hour, minute = ptm_utc_time.split(":").map(&:to_i)
    utc_date = reference_time.utc.to_date
    [ utc_date.yesterday, utc_date ].each do |date|
      slots << [ "PTM", Time.utc(date.year, date.month, date.day, hour, minute) ]
    end
    slots
  end

  def deliver!
    delivered_at = with_lock do
      next if sent_at?

      OperatorChecklistMailer.report(plant: plant, scheduled_at: scheduled_at).deliver_now
      update!(sent_at: Time.current)
      sent_at
    end
    Rails.logger.info("Operator checklist report #{plant} at #{scheduled_at.iso8601} sent") if delivered_at
  end
end
