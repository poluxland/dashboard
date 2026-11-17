class ClinkerDashboard
  PERIODS = { "previous_week" => "Semana pasada", "7" => "Últimos 7 días", "30" => "Últimos 30 días", "month" => "Mes actual", "all" => "Todo" }.freeze
  attr_reader :period, :from, :to, :records

  def initialize(period = nil)
    @period = PERIODS.key?(period) ? period : "month"
    today = Date.current
    @from, @to = case @period
    when "previous_week" then [ today.beginning_of_week - 7, today.beginning_of_week - 1 ]
    when "7", "30" then [ today - (@period.to_i - 1), today ]
    when "all" then [ ClinkerTransfer.minimum(:date) || today, today ]
    else [ today.beginning_of_month, today ]
    end
    @records = ClinkerTransfer.where(date: from..to).order(:date).to_a
  end

  def total
    records.sum { |record| record.tons.to_f }
  end

  def average
    total / records.size if records.any?
  end

  def missing_days
    (to - from).to_i + 1 - records.size
  end

  def peak
    records.max_by(&:tons)
  end

  def charts
    history = ClinkerTransfer.where(date: (from - 6)..to).pluck(:date, :tons).to_h
    days = (from..to).map do |date|
      window = ((date - 6)..date).filter_map { |day| history[day]&.to_f }
      { date: date.iso8601, tons: history[date]&.to_f,
        average: history.key?(date) && window.any? ? window.sum / window.size : nil }
    end
    { days: days, weeks: grouped(:beginning_of_week), months: grouped(:beginning_of_month) }
  end

  def grouped(method)
    records.group_by { |record| record.date.public_send(method) }.map do |date, rows|
      { date: date.iso8601, tons: rows.sum { |row| row.tons.to_f }, days: rows.size }
    end
  end
end
