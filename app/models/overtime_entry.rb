class OvertimeEntry < ApplicationRecord
  PENDING = "Pendiente revisión"
  DECISIONS = %w[Aprobada Rechazada].freeze
  STATUSES = [ PENDING, *DECISIONS ].freeze
  INPUT_FIELDS = %i[fecha descripcion area personal inicio termino he ot traslado lugar mandante ep].freeze
  MANDANTES = [
    "Cesar Hernandez", "Carolina Vera", "Mario Santibañez", "Martin Llancafil",
    "Sergio Miranda", "Johnny Rute", "Oscar Garrido", "Daniel Garrido"
  ].sort.freeze

  self.skip_time_zone_conversion_for_attributes = %i[inicio termino]

  has_many :overtime_reviews
  scope :pending_review, -> { where(estado: PENDING) }

  validates :fecha, :personal, :descripcion, presence: true, on: :capture
  validates :mandante, inclusion: { in: MANDANTES }, on: :capture
  validates :he, numericality: { greater_than_or_equal_to: 0 }, on: :capture
  validates :ot, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true, on: :capture
end
