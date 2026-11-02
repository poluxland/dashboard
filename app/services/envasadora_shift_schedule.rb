class EnvasadoraShiftSchedule
  # Offsets are wall-clock hours from the date the shift starts; 30 is 06:00 next day.
  WEEK = {
    1 => { "TM" => [ 6, 14 ], "TT" => [ 14, 22 ], "TN" => [ 22, 30 ] },
    2 => { "TM" => [ 6, 13 ], "TT" => [ 13, 22 ], "TN" => [ 22, 30 ] },
    3 => { "TM" => [ 6, 13 ], "TT" => [ 13, 22 ], "TN" => [ 22, 30 ] },
    4 => { "TM" => [ 6, 13 ], "TT" => [ 13, 21 ], "TN" => [ 21, 30 ] },
    5 => { "TM" => [ 6, 13 ], "TT" => [ 13, 21 ], "TN" => [ 21, 30 ] },
    6 => { "TM" => [ 6, 12 ] },
    7 => {}
  }.transform_values { |shifts| shifts.transform_values(&:freeze).freeze }.freeze
  MAX_HOURS = 9

  def self.offsets(date, shift)
    WEEK.fetch(date.cwday).fetch(shift) do
      start = { "TM" => 6, "TT" => 13, "TN" => 21 }.fetch(shift)
      [ start, start ]
    end
  end

  def self.hours(date, shift)
    return MAX_HOURS unless date && EnvasadoraReport::SHIFTS.key?(shift)

    start, finish = offsets(date, shift)
    finish - start
  end

  def self.window(date, shift)
    midnight = Time.utc(date.year, date.month, date.day)
    offsets(date, shift).map { |hour| midnight + hour.hours }
  end
end
