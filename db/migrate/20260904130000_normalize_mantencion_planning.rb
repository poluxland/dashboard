class NormalizeMantencionPlanning < ActiveRecord::Migration[8.1]
  FINAL_PLANNING = [ "Plan", "Adicional", "Reprogramado" ].freeze

  PLAN_KEYS = %w[plan paln].freeze
  ADDITIONAL_KEYS = %w[
    adicion
    adicional
    adicional.
    adiciona
    adcional
    adiconal
    adiciopnal
    adicionsl
  ].freeze
  REPROGRAMMED_KEYS = %w[
    reprogramar
    reprogramada
    reprogramado
    reprogramacion
    reprogremar
  ].freeze

  class MantencionRecord < ActiveRecord::Base
    self.table_name = "mantenciones"
  end

  def up
    say_with_time "Normalizando planificación de mantenciones" do
      MantencionRecord.find_each do |record|
        normalized_planning = normalized_planning_for(record.planificacion, record.tipo_mantencion)
        record.update_columns(planificacion: normalized_planning) if record.planificacion != normalized_planning
      end
    end

    change_column_null :mantenciones, :planificacion, false
    add_check_constraint :mantenciones,
                         "planificacion IN ('#{FINAL_PLANNING.join("', '")}')",
                         name: "mantenciones_planificacion_allowed"
  end

  def down
    remove_check_constraint :mantenciones, name: "mantenciones_planificacion_allowed"
    change_column_null :mantenciones, :planificacion, true
  end

  private

  def normalized_planning_for(planning_value, maintenance_type)
    planning = normalization_key(planning_value)
    type = normalization_key(maintenance_type)

    return "Plan" if PLAN_KEYS.include?(planning)
    return "Adicional" if ADDITIONAL_KEYS.include?(planning)
    return "Reprogramado" if REPROGRAMMED_KEYS.include?(planning)
    return "Reprogramado" if type == "reprogramar"
    return "Adicional" if type == "correctivo no programado"

    "Plan"
  end

  def normalization_key(value)
    I18n.transliterate(value.to_s.squish).downcase
  end
end
