class PmmTruckMailer < ApplicationMailer
  helper PmmTrucksHelper

  RECIPIENTS = %w[
    gaston.guerrero@meloncementos.cl catalina.marchant@meloncementos.cl geraldinne.martinez@meloncementos.cl
    manuel.salas@meloncementos.cl camila.ramirez@meloncementos.cl rodolfo.tobar-externo@meloncementos.cl
    jose.jerez@msindustrial.cl fernando.gonzalez@msindustrial.cl simon.rojas@msindustrial.cl
    marcos.prospero@msindustrial.cl hernan.martinez@msindustrial.cl alejandro.olivares@msindustrial.cl
    administracion@msindustrial.cl misael.garrido@msindustrial.cl felipe.sanmartin@meloncementos.cl
    miguel.basulto@meloncementos.cl
  ].freeze

  def report(scheduled_at:)
    local = scheduled_at.in_time_zone(PmmTruck::CHILE)
    @periods = PmmTruckReport.new(local.to_date).periods
    url_options = Rails.env.production? ? { host: "msindustrial.cl", protocol: "https" } : {}
    @truck_url = pmm_trucks_url(**url_options)
    mail(to: RECIPIENTS, subject: "Reporte camiones - #{local.strftime('%d/%m/%Y %H:%M')}")
  end
end
