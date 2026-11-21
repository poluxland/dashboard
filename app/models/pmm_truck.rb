class PmmTruck < ApplicationRecord
  CHILE = Time.find_zone!("America/Santiago")
  TYPES = [ "Plano", "BRU", "Batea 20", "Batea 40", "Silo", "Otro" ].freeze
  CAUSES = [ "Normal", "Masivo", "Paisas colación", "Paisas cambio turno", "sin BRU", "BRU sin caídas",
            "Falla Cargador frontal", "Exceso puntos de atención", "Sobrestock", "Otros" ].freeze
  INPUTS = %i[fecha pmm_material_id tipo llegada llamada salida patente cause motive number other].freeze

  self.skip_time_zone_conversion_for_attributes = %i[llegada llamada salida]

  belongs_to :pmm_material
  validates :patente, :fecha, :llegada, :tipo, presence: true, on: :capture
  normalizes :patente, with: ->(value) { value.strip.upcase }

  before_validation :set_wait, on: :capture, if: -> { new_record? || will_save_change_to_llegada? || will_save_change_to_salida? }

  scope :measured, -> { where(finished: true).or(where(finished: nil, wait: 1..)) }
  scope :on_site, ->(today) { where(finished: false).or(where(finished: nil, wait: ..1, fecha: today)) }

  def pending?
    finished.nil? ? salida.nil? || wait.to_i <= 1 : !finished
  end

  private

  def set_wait
    self.finished = salida.present?
    self.wait = ((salida - llegada) % 1.day.to_i / 60).to_i if salida && llegada
    self.wait = nil if salida.nil?
  end
end
