class AprDay < ApplicationRecord
  ZONE = "America/Santiago"
  PLANTS = { "PTM" => "Puerto Montt", "LCA" => "La Calera", "VTS" => "Ventanas", "CALBUCO" => "Calbuco" }.freeze

  belongs_to :apr, class_name: "DashboardUser"
  has_many :activities, class_name: "AprActivity", dependent: :restrict_with_exception

  validates :date, presence: true, comparison: { less_than_or_equal_to: -> { AprDay.today } }
  validates :plant, inclusion: { in: PLANTS.keys }
  validates :closed_by_email, :recipients, presence: true, if: :closed_at?

  def self.today
    Time.current.in_time_zone(ZONE).to_date
  end

  def recipients_for_close
    configured = ENV.fetch("APR_ACTIVITY_REPORT_RECIPIENTS_#{plant}", "").split(/[,;\s]+/)
    [ apr.email, *configured ].map { |email| email.strip.downcase }.select do |email|
      email.match?(URI::MailTo::EMAIL_REGEXP)
    end.uniq
  end

  def close!(email)
    records = activities.order(:id).to_a
    if records.empty?
      errors.add(:base, "Registra al menos una actividad antes de cerrar el día.")
      raise ActiveRecord::RecordInvalid, self
    end

    update!(closed_at: Time.current, closed_by_email: email, recipients: recipients_for_close,
      email_summary: {
        count: records.size,
        minutes: records.sum(&:duration_minutes),
        severe: records.count { |activity| activity.severity == "grave" },
        sectors: records.group_by(&:sector).sort.map do |sector, items|
          { sector: sector, count: items.size, minutes: items.sum(&:duration_minutes),
            severe: items.count { |activity| activity.severity == "grave" } }
        end,
        pending: records.select(&:open_follow_up?).map do |activity|
          { sector: activity.sector, activity_type: activity.activity_type,
            due_on: activity.due_on.iso8601, severity: activity.severity }
        end
      })
  end
end
