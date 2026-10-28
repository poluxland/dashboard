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
end
