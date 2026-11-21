module OvertimeEntriesHelper
  def overtime_time(value)
    value&.strftime("%H:%M")
  end

  def overtime_quantity(value)
    number_with_precision(value, precision: 2, strip_insignificant_zeros: true) if value
  end
end
