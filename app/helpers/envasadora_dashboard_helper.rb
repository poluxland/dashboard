module EnvasadoraDashboardHelper
  def dashboard_number(value, precision: 1, suffix: "")
    return "—" if value.nil?

    "#{number_with_precision(value, precision: precision, strip_insignificant_zeros: true, delimiter: '.', separator: ',')}#{suffix}"
  end

  def dashboard_vorne_kpis(report)
    [
      [ "Detenido por turno", dashboard_number(report.downtime_per_shift, suffix: " min"), "turnos con registros TPT" ],
      [ "Tiempo detenido", dashboard_number(report.downtime_percentage, suffix: "%"), "del tiempo registrado en TPT" ],
      [ "Disponibilidad observada", dashboard_number(report.availability, suffix: "%"), "sobre tiempo de operación registrado" ],
      [ "MTBF", dashboard_number(report.mtbf, suffix: " h"), "horas en marcha entre paradas no planificadas" ],
      [ "MTTR", dashboard_number(report.mttr, suffix: " min"), "minutos por parada no planificada" ],
      [ "Confiabilidad estimada (8 h)", dashboard_number(report.reliability, suffix: "%"), "estimación a partir del MTBF" ]
    ]
  end
end
