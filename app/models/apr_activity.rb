class AprActivity < ApplicationRecord
  SECTORS = [ "Granel", "Envasado", "Materias Primas", "Taller", "Transversal", "Otro" ].freeze
  ACTIVITY_TYPES = [
    "Inspección", "Revisión de AST", "Permiso de trabajo", "Capacitación", "Entrega de EPP",
    "Gestión documental", "Reunión", "Coordinación", "Otro"
  ].freeze
  OUTCOMES = { "none" => "Sin hallazgos", "corrected" => "Corregido en el momento", "follow_up" => "Requiere seguimiento" }.freeze
  SEVERITIES = { "leve" => "Leve", "moderada" => "Moderada", "grave" => "Grave" }.freeze
  FOLLOW_UP_STATUSES = { "pending" => "Pendiente", "in_progress" => "En seguimiento", "closed" => "Cerrado" }.freeze

  belongs_to :apr_day

  scope :follow_ups, -> { where(outcome: "follow_up") }
  scope :open_follow_ups, -> { follow_ups.where(follow_up_status: %w[pending in_progress]) }

  attr_writer :duration_hours, :duration_remainder

  normalizes :title, :observations, :responsible, :resolution, with: ->(text) { text.strip.presence }
  before_validation :set_duration, if: -> { instance_variable_defined?(:@duration_hours) || instance_variable_defined?(:@duration_remainder) }
  before_validation :set_finding_fields

  validates :sector, inclusion: { in: SECTORS }
  validates :activity_type, inclusion: { in: ACTIVITY_TYPES }
  validates :outcome, inclusion: { in: OUTCOMES.keys }
  validates :title, presence: true, length: { maximum: 180 }
  validates :observations, :resolution, length: { maximum: 5000 }
  validates :duration_minutes, numericality: { only_integer: true, in: 1..1440, message: "debe estar entre 1 minuto y 24 horas" }
  validates :severity, inclusion: { in: SEVERITIES.keys }, if: -> { outcome.in?(%w[corrected follow_up]) }
  validates :responsible, presence: true, length: { maximum: 150 }, if: :follow_up?
  validates :due_on, presence: true, if: :follow_up?
  validates :follow_up_status, inclusion: { in: FOLLOW_UP_STATUSES.keys }, if: :follow_up?
  validates :resolution, :resolved_at, :resolved_by_email, presence: true, if: :follow_up_closed?
  validate :preserve_closed_follow_up

  def duration_hours
    @duration_hours || duration_minutes&.div(60)
  end

  def duration_remainder
    @duration_remainder || duration_minutes&.modulo(60)
  end

  def follow_up?
    outcome == "follow_up"
  end

  def open_follow_up?
    follow_up? && !follow_up_closed?
  end

  def follow_up_closed?
    follow_up_status == "closed"
  end

  private

  def set_duration
    hours = Integer(@duration_hours.to_s.presence || "0", 10, exception: false)
    minutes = Integer(@duration_remainder.to_s.presence || "0", 10, exception: false)
    self.duration_minutes = (hours * 60 + minutes if hours&.between?(0, 24) && minutes&.between?(0, 59))
  end

  def set_finding_fields
    self.severity = nil if outcome == "none"
    if follow_up?
      self.follow_up_status ||= "pending"
    else
      self.responsible = self.due_on = self.follow_up_status = nil
      self.resolution = self.resolved_at = self.resolved_by_email = nil
    end
  end

  def preserve_closed_follow_up
    if follow_up_status_in_database == "closed" && !follow_up?
      errors.add(:outcome, "debe conservar el seguimiento que ya se cerró")
    end
  end
end
