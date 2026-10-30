module EnvasadoraReportsHelper
  def envasadora_number(value)
    number_with_precision(value, precision: 0, delimiter: ".", separator: ",")
  end

  def envasadora_decimal(value)
    number_with_precision(value, precision: 2, strip_insignificant_zeros: true, delimiter: ".", separator: ",")
  end

  def envasadora_input_value(value)
    value.is_a?(Numeric) && value == value.to_i ? value.to_i : value
  end

  def envasadora_historical_value(report, column)
    corrections = report.source_data.fetch("corrections", [])
    original = report.source_data.fetch("cells", {})[column["header"]].presence || "—"
    if corrections.any? { |entry| entry["field"] == column["field"] }
      return { value: envasadora_decimal(report.public_send(column["field"])), change: "Corregido", original: original }
    end
    rates = { "Haver Ton/h" => %w[horas_haver prodhaver], "Vento Ton/h" => %w[horas_vento prodvento], "Bigbag Ton/h" => %w[horas_bigbag prodbb] }
    if (fields = rates[column["header"]]) && corrections.any? { |entry| entry["field"] == fields.first }
      hours = report.value_for_analytics(fields.first)
      units = report.value_for_analytics(fields.last)
      factor = fields.last == "prodbb" ? BigDecimal("1.5") : BigDecimal("0.025")
      rate = hours&.positive? && units ? envasadora_decimal(units * factor / hours) : "—"
      return { value: rate, change: "Recalculado", original: original }
    end
    { value: original }
  end
end
