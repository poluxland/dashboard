class EquipmentChecklist < ApplicationRecord
  QUESTIONS = {
    c1: "Equipo libre de fugas",
    c2: "Equipo libre de pernos sueltos o quebraduras",
    c3: "Responden todos los movimientos",
    c4: "Funcionan correctamente los frenos",
    c5: "Pasadores en buen estado",
    c6: "Todos los espejos están operativos",
    c7: "Cinturón de seguridad operativo",
    c8: "Neumáticos en buen estado",
    c9: "Funciona la alarma de retroceso",
    c10: "Funciona la bocina",
    c11: "Funcionan las luces",
    c12: "Equipo libre de alarmas",
    c13: "Se realizó el engrase del equipo",
    c14: "Parabrisas en perfecto estado",
    c15: "El equipo cuenta con pértiga",
    c16: "Extintor operativo"
  }.freeze
  ANSWERS = { "Si" => "Sí", "No(leve)" => "No leve", "No(grave)" => "No grave", "No aplica" => "No aplica" }.freeze
  PLANTS = {
    "LCA" => "La Calera", "PTM" => "Puerto Montt", "VTS" => "Ventanas", "PAM" => "PAM", "Otros" => "Otros"
  }.freeze
  STATUSES = {
    "grave" => [ "Con falla grave", "danger" ],
    "leve" => [ "Con falla leve", "warning" ],
    "sin_clasificar" => [ "Con falla sin clasificación", "warning" ],
    "incompleto" => [ "Incompleto", "secondary" ],
    "sin_fallas" => [ "Sin fallas", "success" ]
  }.freeze
  ANSWER_ARRAY = "ARRAY[#{QUESTIONS.keys.map { |column| "equipment_checklists.#{column}" }.join(', ')}]".freeze
  STATUS_SQL = <<~SQL.squish.freeze
    CASE
      WHEN 'No(grave)' = ANY(#{ANSWER_ARRAY}) THEN 'grave'
      WHEN 'No(leve)' = ANY(#{ANSWER_ARRAY}) THEN 'leve'
      WHEN 'No' = ANY(#{ANSWER_ARRAY}) THEN 'sin_clasificar'
      WHEN '' = ANY(#{ANSWER_ARRAY}) OR array_position(#{ANSWER_ARRAY}, NULL) IS NOT NULL THEN 'incompleto'
      ELSE 'sin_fallas'
    END
  SQL

  belongs_to :mobile_asset, optional: true

  validates :mobile_asset, presence: true, if: -> { new_record? || will_save_change_to_mobile_asset_id? }
  validates :operator, presence: true, if: -> { new_record? || will_save_change_to_operator? }
  validates :hour_meter, numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            if: -> { new_record? || will_save_change_to_hour_meter? }
  validates :c17, inclusion: { in: PLANTS.keys }, if: -> { new_record? || will_save_change_to_c17? }

  QUESTIONS.each_key do |field|
    validates field, inclusion: { in: ANSWERS.keys }, if: -> { new_record? || will_save_change_to_attribute?(field) }
  end

  def asset_label
    mobile_asset&.label || legacy_code.presence || "Sin equipo registrado"
  end

  def plant_label
    PLANTS.fetch(c17, c17).presence || "Sin planta registrada"
  end

  def status_key
    answers = QUESTIONS.keys.map { |field| self[field] }
    return "grave" if answers.include?("No(grave)")
    return "leve" if answers.include?("No(leve)")
    return "sin_clasificar" if answers.include?("No")
    return "incompleto" if answers.any? { |answer| answer.nil? || answer.empty? }

    "sin_fallas"
  end
end
