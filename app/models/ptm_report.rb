class PtmReport < ApplicationRecord
  SHIFTS = { "TN" => "Noche", "TM" => "Mañana", "TT" => "Tarde" }.freeze
  has_many :ptm_events, dependent: :destroy, inverse_of: :ptm_report
  accepts_nested_attributes_for :ptm_events, allow_destroy: true, reject_if: :all_blank
  validates :date, :author_email, presence: true
  validates :shift, inclusion: { in: SHIFTS.keys }, uniqueness: { scope: :date }
  validates :production, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validate :event_minutes_fit_shift, unless: -> { source_key.present? }

  def stopped_minutes
    ptm_events.reject(&:marked_for_destruction?).sum { |event| event.minutes.to_f }
  end

  def usable_times?
    review_notes.blank? && ptm_events.all? { |event| event.minutes.present? } && stopped_minutes <= 480
  end

  private

  def event_minutes_fit_shift
    errors.add(:base, "Las detenciones no pueden superar los 480 minutos del turno.") if stopped_minutes > 480
  end
end
