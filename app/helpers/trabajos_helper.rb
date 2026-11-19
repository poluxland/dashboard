module TrabajosHelper
  def monto_trabajo(value)
    number_to_currency(value || 0, unit: "$", precision: 0, delimiter: ".", format: "%u%n", negative_format: "-%u%n")
  end

  def estado_trabajo(value)
    return "En ejecución" if value == Trabajo::EN_EJECUCION

    value.presence || "Sin estado"
  end

  def nombre_planta_trabajo(value)
    Trabajo::PLANTAS_NOMBRES.fetch(value, value)
  end

  def mes_trabajo(date)
    %w[enero febrero marzo abril mayo junio julio agosto septiembre octubre noviembre diciembre][date.month - 1].capitalize + " #{date.year}"
  end
end
