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

  def apr_history_activity_summaries(entry)
    entry.activities.each_index.map do |index|
      details = entry.activity_details.fetch((index + 1).to_s, {})
      type = details["type"].presence || "Actividad registrada"
      fields = details.values_at("sector", "place", "modality", "equipment", "reference", "platform", "result")
      [ type, *fields.compact_blank ].join(" · ")
    end
  end
end
