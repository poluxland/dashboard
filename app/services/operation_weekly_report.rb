class OperationWeeklyReport
  attr_reader :start_date, :end_date, :records

  def self.local_today
    Time.find_zone!("America/Santiago").today
  end

  def self.previous_week
    local_today - 1.week
  end

  def initialize(week_of: self.class.previous_week)
    @start_date = week_of.beginning_of_week(:monday)
    @end_date = start_date + 6.days
    @records = OperationActivity.where(fecha: start_date..end_date).order(:fecha, :id).to_a
  end

  def week_number
    start_date.cweek
  end

  def title
    "Informe semanal de operaciones · Semana #{week_number}"
  end

  def average_state
    return if records.empty?

    (records.sum(&:estado) / records.size).round(1)
  end

  def summary_counts
    counts = records.map(&:tipo).tally
    summary = {
      "Actividades" => records.size,
      "Programadas" => counts.fetch("Programada", 0),
      "Por reprogramar" => counts.fetch("Reprogramar", 0),
      "Contingencias" => counts.fetch("Contingencia", 0)
    }
    unclassified = counts.fetch(OperationActivity::UNCLASSIFIED_TYPE, 0)
    summary[OperationActivity::UNCLASSIFIED_TYPE] = unclassified if unclassified.positive?
    summary
  end

  def area_counts
    records.map(&:area).tally.sort_by { |area, count| [ -count, area ] }
  end

  def state_counts
    complete = records.count { |record| record.estado == 100 }
    pending = records.count { |record| record.estado.zero? }
    {
      "Completadas" => complete,
      "En progreso" => records.size - complete - pending,
      "No iniciadas" => pending
    }
  end
end
