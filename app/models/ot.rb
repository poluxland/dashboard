# app/models/ot.rb
class Ot < ApplicationRecord
  # --- Validaciones y callbacks (los tuyos) ---
  validates :ot_asignada, presence: true, uniqueness: true, numericality: { only_integer: true }
  validates :semana, :item, numericality: { only_integer: true }, allow_nil: true
  validates :cantidad, :unitario, :servicio,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true
  before_save :calcular_repuestos_y_total, if: :insumos_cambiaron?

  # --- BÚSQUEDA ---
  TEXT_COLS    = %w[codigo actividad_semanal area esp cc responsable contratista tipo_ot causa comentarios cod_rep].freeze
  NUMERIC_COLS = %w[
    semana item frecuencia cantidad unitario servicio cotizacion
    estado sem_ejec n_personas duracion_hr hh repuestos total ot_asignada
  ].freeze

  scope :search, ->(q) {
  return all if q.blank?

  s = q.to_s.strip
  like = "%#{ActiveRecord::Base.sanitize_sql_like(s)}%"
  table = arel_table

  text_conditions = TEXT_COLS.map { |col| table[col].matches(like) }
  condition = text_conditions.inject { |memo, expr| memo.or(expr) }

  if (num = Integer(s) rescue nil)
    num_conditions = NUMERIC_COLS.map { |col| table[col].eq(num) }
    condition = condition.or(num_conditions.inject { |memo, expr| memo.or(expr) })
  end

  where(condition)
}




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
