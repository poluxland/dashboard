class OperationActivity < ApplicationRecord
  AREA_OPTIONS = [
    "Alimentadores y cintas",
    "Bodega Big Bag",
    "Calbuco",
    "Corporativo y servicios generales",
    "Envasadora",
    "Generador de calor",
    "Granel, silos y puntos de carga",
    "Materias primas y acopios",
    "Molino PTM-1",
    "Molino PTM-2",
    "Patio de salvataje y reciclaje",
    "Porteo interno"
  ].freeze

  UNCLASSIFIED_TYPE = "Sin clasificar".freeze
  TIPOS = [ "Programada", "Reprogramar", "Contingencia", UNCLASSIFIED_TYPE ].freeze

  validates :fecha, :actividad, presence: true
  validates :area, inclusion: { in: AREA_OPTIONS }
  validates :tipo, inclusion: { in: TIPOS }
  validates :estado, numericality: { in: 0..100 }
end
