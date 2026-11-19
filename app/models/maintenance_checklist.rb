class MaintenanceChecklist < ApplicationRecord
  QUESTIONS = {
    c1: "Revisó el nivel de aceite del motor",
    c2: "Revisó el nivel de aceite hidráulico y de transmisión",
    c3: "Revisó el nivel de líquido de frenos",
    c4: "Revisó el nivel de líquido refrigerante",
    c5: "Revisó el nivel de líquido limpiaparabrisas",
    c6: "Revisó o coordinó el engrase diario",
    c7: "Revisó el estado del filtro y la válvula de aire",
    c8: "Revisó el filtro separador de combustible",
    c9: "Revisó el estado general del panel del radiador",
    c10: "Revisó el equipo en búsqueda de fugas",
    c11: "Revisó el estado de los neumáticos",
    c12: "Revisó el estado general de pernos, pasadores y pantógrafo",
    c13: "Realizó limpieza del antefiltro del motor",
    c14: "Consultó al operador por el estado de las luces",
    c15: "Consultó al operador por la bocina y la alarma de retroceso",
    c16: "Consultó al operador por posibles alarmas en el panel",
    c17: "Consultó al operador por el estado del freno del equipo",
    c18: "Consultó al operador por el estado de la dirección y la marcha del equipo",
    c19: "Se encuentran todos los artículos de limpieza en la cabina"
  }.freeze
  FLUIDS = {
    fuel: "Combustible",
    engine_oil: "Aceite motor Super 1400",
    hydraulic_oil: "Aceite hidráulico HD10",
    transmission_oil: "Aceite transmisión 1340",
    atf_oil: "Aceite ATF 220",
    nuto_oil: "Aceite NUTOH46"
  }.freeze
  STATUSES = {
    "Operativo" => [ "operativo", "success" ],
    "Observaciones" => [ "observaciones", "warning" ],
    "Fuera de servicio" => [ "fuera_servicio", "danger" ]
  }.freeze
  ANSWERS = { true => "Sí", false => "No", nil => "Sin registro" }.freeze

  belongs_to :mobile_asset, optional: true
  validates :mobile_asset, presence: true, if: -> { new_record? || will_save_change_to_mobile_asset_id? }
  validates :operating_status, inclusion: { in: STATUSES.keys }, allow_blank: true, if: :will_save_change_to_operating_status?

  def asset_label
    mobile_asset&.label || legacy_code.presence || "Sin equipo registrado"
  end
end
