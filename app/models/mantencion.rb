class Mantencion < ApplicationRecord
  PLANNING_OPTIONS = [ "Plan", "Adicional", "Reprogramado" ].freeze
  MAINTENANCE_TYPE_OPTIONS = [
    "Preventiva",
    "Correctivo Programado",
    "Correctivo No programado",
    "Reprogramar"
  ].freeze

  SPECIALTY_LABELS = {
    "electrica" => "Eléctrico",
    "electrico" => "Eléctrico",
    "mecanica" => "Mecánico",
    "mecanico" => "Mecánico",
    "instrumentacion" => "Instrumentación"
  }.freeze

  PLANNING_LABELS = {
    "plan" => "Plan",
    "paln" => "Plan",
    "planificada" => "Plan",
    "planificado" => "Plan",
    "adicion" => "Adicional",
    "adicional" => "Adicional",
    "adicional." => "Adicional",
    "adiciona" => "Adicional",
    "adcional" => "Adicional",
    "adiconal" => "Adicional",
    "adiciopnal" => "Adicional",
    "adicionsl" => "Adicional",
    "reprogramacion" => "Reprogramado",
    "reprogramada" => "Reprogramado",
    "reprogramado" => "Reprogramado",
    "reprogramar" => "Reprogramado",
    "reprogremar" => "Reprogramado"
  }.freeze

  PROGRAMMED_PLANNING_KEYS = %w[programada programado preventiva preventivo].freeze

  MAINTENANCE_TYPE_LABELS = {
    "preventiva" => "Preventiva",
    "preventivo" => "Preventiva",
    "prventiva" => "Preventiva",
    "correctiva programada" => "Correctivo Programado",
    "correctivo programado" => "Correctivo Programado",
    "correctiva no programada" => "Correctivo No programado",
    "correctivo no programado" => "Correctivo No programado",
    "puesta en marcha" => "Puesta en marcha",
    "reprogramada" => "Reprogramar",
    "reprogramado" => "Reprogramar",
    "reprogramar" => "Reprogramar"
  }.freeze

  before_validation :normalize_categorical_fields
  before_validation :complete_week_from_date
  before_validation :complete_state_from_work_evidence

  validates :fecha, :especialidad, :actividad, presence: true
  validates :semana,
            numericality: { only_integer: true, in: 1..53 },
            allow_nil: true
  validates :estado,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
            allow_nil: true
  validates :duracion,
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: true
  validates :planificacion, inclusion: { in: PLANNING_OPTIONS }
  validates :tipo_mantencion, inclusion: { in: MAINTENANCE_TYPE_OPTIONS }

  class << self
    def normalization_key(value)
      I18n.transliterate(value.to_s.squish).downcase
    end

    def canonical_specialty(value)
      canonical_value(value, SPECIALTY_LABELS)
    end

    def canonical_planning(value, maintenance_type: nil)
      planning_key = normalization_key(value)
      mapped = PLANNING_LABELS[planning_key]
      return mapped if PLANNING_OPTIONS.include?(mapped)

      type_key = normalization_key(maintenance_type)
      return "Reprogramado" if type_key == "reprogramar"
      return "Adicional" if type_key == "correctivo no programado"
      return "Plan" if [ "preventiva", "correctivo programado" ].include?(type_key)
      return "Plan" if PROGRAMMED_PLANNING_KEYS.include?(planning_key)

      "Adicional"
    end

    def canonical_maintenance_type(value, planning: nil)
      planning_label = canonical_planning(planning)
      return "Reprogramar" if planning_label == "Reprogramado"

      cleaned = value.to_s.squish
      type_key = normalization_key(cleaned)
      mapped = MAINTENANCE_TYPE_LABELS[type_key]
      return mapped if MAINTENANCE_TYPE_OPTIONS.include?(mapped)
      return "Correctivo No programado" if type_key.include?("no program") || type_key.include?("no planific")
      return "Correctivo Programado" if type_key.include?("correct") && type_key.include?("program")

      planning_label == "Plan" ? "Correctivo Programado" : "Correctivo No programado"
    end

    def canonical_identifier(value)
      value.to_s.squish.upcase.presence
    end

    private

    def canonical_value(value, labels)
      cleaned = value.to_s.squish
      return if cleaned.blank?

      labels.fetch(normalization_key(cleaned)) do
        cleaned.downcase.capitalize
      end
    end
  end

  private

  def normalize_categorical_fields
    self.especialidad = self.class.canonical_specialty(especialidad)
    normalized_type = self.class.canonical_maintenance_type(tipo_mantencion, planning: planificacion)
    self.planificacion = self.class.canonical_planning(planificacion, maintenance_type: normalized_type)
    self.tipo_mantencion = normalized_type
    self.area = self.class.canonical_identifier(area)
    self.codigo = self.class.canonical_identifier(codigo)
    self.numero_ot = numero_ot.to_s.squish.presence
  end

  def complete_week_from_date
    self.semana = fecha.cweek if semana.blank? && fecha.present?
  end

  def complete_state_from_work_evidence
    return if estado.present?

    self.estado = 100 if comentarios.to_s.strip.present? || duracion.to_f.positive?
  end
end
