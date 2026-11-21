module PmmTrucksHelper
  def pmm_time(value)
    value&.strftime("%H:%M")
  end

  def pmm_metric(value)
    value.nil? ? "—" : number_with_precision(value, precision: 1, strip_insignificant_zeros: true)
  end

  def pmm_compliance(count, within)
    count.positive? ? number_to_percentage(100.0 * within / count, precision: 1) : "—"
  end
end
