# app/models/ot.rb
class Ot < ApplicationRecord
  # --- Validaciones clave ---
  validates :ot_asignada, presence: true, uniqueness: true, numericality: { only_integer: true }
  validates :semana, :item, numericality: { only_integer: true }, allow_nil: true
  validates :cantidad, :unitario, :servicio,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true

  # --- Cálculo automático ---
  before_save :calcular_repuestos_y_total, if: :insumos_cambiaron?

  private

  def insumos_cambiaron?
    will_save_change_to_cantidad? || will_save_change_to_unitario? || will_save_change_to_servicio?
  end

  def calcular_repuestos_y_total
    c = cantidad.to_i
    u = unitario.to_i
    s = servicio.to_i
    self.repuestos = c * u
    self.total     = repuestos.to_i + s
  end
end
