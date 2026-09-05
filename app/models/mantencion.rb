class Mantencion < ApplicationRecord
  PLANNING_OPTIONS = [ "Plan", "Adicional", "Reprogramado" ].freeze
  MAINTENANCE_TYPE_OPTIONS = [ "Preventiva", "Correctivo Programado", "Correctivo No programado" ].freeze

  SPECIALTY_LABELS = {
    "electrica" => "Eléctrico",
    "electrico" => "Eléctrico",
    "mecanica" => "Mecánico",
    "mecanico" => "Mecánico",
    "instrumentacion" => "Instrumentación"
  }.freeze

  PLANNING_LABELS = {
    "plan" => "Plan",
    "planificada" => "Plan",
    "planificado" => "Plan",
    "adicion" => "Adicional",
    "adicional" => "Adicional",
    "adiciona" => "Adicional",
    "adicionsl" => "Adicional",
    "programada" => "Programado",
    "programado" => "Programado",
    "reprogramacion" => "Reprogramado",
    "reprogramada" => "Reprogramado",
    "reprogramado" => "Reprogramado",
    "reprogramar" => "Reprogramado"
  }.freeze

  MAINTENANCE_TYPE_LABELS = {
    "preventiva" => "Preventiva",
    "preventivo" => "Preventiva",
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

  class << self
    def normalization_key(value)
      I18n.transliterate(value.to_s.squish).downcase
    end

    def canonical_specialty(value)
      canonical_value(value, SPECIALTY_LABELS)
    end

    def canonical_planning(value)
      canonical_value(value, PLANNING_LABELS)
    end

    def canonical_maintenance_type(value)
      canonical_value(value, MAINTENANCE_TYPE_LABELS)
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
    self.planificacion = self.class.canonical_planning(planificacion)
    self.tipo_mantencion = self.class.canonical_maintenance_type(tipo_mantencion)
    self.area = self.class.canonical_identifier(area)
    self.codigo = self.class.canonical_identifier(codigo)
    self.numero_ot = numero_ot.to_s.squish.presence
  end

  def complete_week_from_date
    self.semana = fecha.cweek if semana.blank? && fecha.present?
  end
end
