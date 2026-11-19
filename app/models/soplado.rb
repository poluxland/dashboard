class Soplado < ApplicationRecord
  ZONE = "America/Santiago"
  MEASUREMENTS = {
    presion1: [ "Ducto ascendente P1", "24" ],
    presion2: [ "Ducto ascendente P2", "2,5" ],
    presion3: [ "CC54 P1", "25" ],
    presion4: [ "CC54 P2", "6" ],
    presion5: [ "CC54 Temp", "850" ],
    presion6: [ "Quench P1", "3,5" ],
    horno: [ "Alimentación horno (t/h)", "120,0" ],
    carbon_horno: [ "Carbón horno (t/h)", nil ],
    carbon_precalcinador: [ "Carbón precalcinador (t/h)", nil ],
    so3: [ "SO3", nil ]
  }.freeze

  LABELS = {
    fecha: "Fecha y hora",
    supervisor: "Supervisor",
    **MEASUREMENTS.transform_values(&:first),
    jetin: "Jetin",
    mirillas: "Estado de mirillas",
    tiempo: "Tiempo de la tarea (min)",
    operadores: "Número de operadores",
    observaciones: "Observaciones"
  }.freeze

  validates :fecha, presence: true
  validates :supervisor, presence: true, on: :create
  validates :supervisor, :mirillas, length: { maximum: 255 }
  validates :observaciones, length: { maximum: 5000 }
  validates(*MEASUREMENTS.keys, numericality: true, allow_nil: true)
  validates :tiempo, :operadores, numericality: { only_integer: true, in: (0...2**31) }, allow_nil: true

  def local_fecha
    fecha&.in_time_zone(ZONE)
  end
end
