module SopladosHelper
  def soplado_value(soplado, field)
    value = soplado.public_send(field)
    return "—" if value.nil? || value == ""

    case field
    when :fecha then soplado.local_fecha.strftime("%d/%m/%Y %H:%M")
    when :jetin then value ? "Sí" : "No"
    else value
    end
  end
end
