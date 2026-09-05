class NormalizeMantencionTypes < ActiveRecord::Migration[8.1]
  FINAL_TYPES = [
    "Preventiva",
    "Correctivo Programado",
    "Correctivo No programado",
    "Reprogramar"
  ].freeze

  PREVENTIVE_KEYS = %w[preventiva preventivo prventiva].freeze
  REPROGRAMMED_KEYS = %w[reprogramar reprogramada reprogramado reprogramacion].freeze

  class MantencionRecord < ActiveRecord::Base
    self.table_name = "mantenciones"
  end

  def up
    say_with_time "Normalizando tipos de mantención" do
      MantencionRecord.find_each do |record|
        normalized_type = normalized_type_for(record.tipo_mantencion, record.planificacion)
        record.update_columns(tipo_mantencion: normalized_type) if record.tipo_mantencion != normalized_type
      end
    end

    change_column_null :mantenciones, :tipo_mantencion, false
    add_check_constraint :mantenciones,
                         "tipo_mantencion IN ('#{FINAL_TYPES.join("', '")}')",
                         name: "mantenciones_tipo_mantencion_allowed"
  end

  def down
    remove_check_constraint :mantenciones, name: "mantenciones_tipo_mantencion_allowed"
    change_column_null :mantenciones, :tipo_mantencion, true
  end

  private

  def normalized_type_for(type_value, planning_value)
    type = normalization_key(type_value)
    planning = normalization_key(planning_value)

    return "Reprogramar" if REPROGRAMMED_KEYS.include?(planning) || REPROGRAMMED_KEYS.include?(type)
    return "Preventiva" if PREVENTIVE_KEYS.include?(type)
    return "Correctivo No programado" if type.include?("no program") || type.include?("no planific")
    return "Correctivo Programado" if type.include?("correct") && type.include?("program")
    return "Correctivo Programado" if planning == "plan"

    "Correctivo No programado"
  end

  def normalization_key(value)
    I18n.transliterate(value.to_s.squish).downcase
  end
end
