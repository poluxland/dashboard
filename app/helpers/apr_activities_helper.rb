module AprActivitiesHelper
  def apr_duration(minutes)
    hours, remainder = minutes.divmod(60)
    hours.positive? ? "#{hours} h #{remainder} min" : "#{remainder} min"
  end

  def apr_plant_options
    AprDay::PLANTS.map { |code, name| [ code == "CALBUCO" ? name : "#{code} · #{name}", code ] }
  end
end
