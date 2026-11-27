module AprActivitiesHelper
  def apr_duration(minutes)
    hours, remainder = minutes.divmod(60)
    hours.positive? ? "#{hours} h #{remainder} min" : "#{remainder} min"
  end

  def apr_plant_options
    AprDay::PLANTS.map { |code, name| [ code == "CALBUCO" ? name : "#{code} · #{name}", code ] }
  end

  def apr_history_period(entry)
    start = l(entry.date, format: :short)
    entry.date == entry.end_date ? start : "#{start} al #{l(entry.end_date, format: :short)}"
  end
end
