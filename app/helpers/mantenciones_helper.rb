module MantencionesHelper
  def breakdown_percentage(count, total)
    value = total.zero? ? 0 : count * 100.0 / total
    "#{number_with_precision(value, precision: 1, strip_insignificant_zeros: true)}%"
  end

  def breakdown_tone(label)
    {
      "Adicional" => "additional", "Plan" => "plan",
      "Preventiva" => "preventive", "Correctivo Programado" => "scheduled",
      "Correctivo No programado" => "unscheduled"
    }.fetch(label, "other")
  end
end
