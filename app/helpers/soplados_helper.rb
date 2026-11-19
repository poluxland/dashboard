module SopladosHelper
  def soplado_export_values(soplado)
    [ soplado.id, soplado.erp_id, *Soplado::LABELS.keys.map { |field| soplado_value(soplado, field, missing: nil) } ]
  end

  def soplado_value(soplado, field, missing: "—")
    value = soplado.public_send(field)
    return missing if value.nil? || value == ""

    case field
    when :fecha then soplado.local_fecha.strftime("%d/%m/%Y %H:%M")
    when :jetin then value ? "Sí" : "No"
    else value
    end
  end
end
