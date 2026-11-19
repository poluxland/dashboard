class Trabajo < ApplicationRecord
  PLANTAS = {
    "La Calera" => "LCA", "Ventanas" => "VTS", "P.Montt" => "PTM", "P.Arenas" => "PUQ"
  }.freeze
  PLANTAS_NOMBRES = {
    "La Calera" => "La Calera", "Ventanas" => "Ventanas", "P.Montt" => "Puerto Montt", "P.Arenas" => "Punta Arenas"
  }.freeze
  EN_EJECUCION = "En ejecucción"
  ESTADOS = [ "Cotizada", "Aprobada", EN_EJECUCION, "Terminado", "Facturado", "Cancelada", "Rechazado" ].freeze
  FINALIZADOS = [ "Terminado", "Facturado" ].freeze
  CENTROS = [ "Cmec", "Horno", "Ser", "Trans", "Env", "Vts", "Ext Vts", "Adm", "Ptm", "Ext Ptm", "Ngp", "PUQ", "Otro" ].freeze
  CLASIFICACIONES = [ "Servicios", "Compras", "Mano de obra" ].freeze
  ITEMS = (1..12).freeze
  ITEM_AMOUNTS = ITEMS.flat_map { |number| [ "q#{number}", "v#{number}" ] }.freeze
  ITEM_FIELDS = (ITEMS.map { |number| "i#{number}" } + ITEM_AMOUNTS).map(&:to_sym).freeze

  scope :terminados, -> { where(avance: "Terminado") }
  scope :finalizados, -> { where(avance: FINALIZADOS) }
  scope :en_ejecucion, -> { where(avance: EN_EJECUCION) }
  scope :sin_op, -> { where(op: [ nil, 0 ]) }
  scope :con_op, -> { where.not(op: nil).where.not(op: 0) }

  before_validation :calcular_total, if: -> { new_record? || changes_to_save.keys.intersect?(ITEM_AMOUNTS) }
  validates :op, :factura, *ITEM_AMOUNTS, numericality: { only_integer: true, in: (-2**31...2**31) }, allow_nil: true
  validates :total, numericality: { only_integer: true, in: (-2**63...2**63) }, allow_nil: true

  def referencia
    erp_id || "D-#{id}"
  end

  def subtotal(number)
    self["q#{number}"].to_i * self["v#{number}"].to_i
  end

  private

  def calcular_total
    self.total = ITEMS.sum { |number| subtotal(number) }
  end
end
