class SopladoMailer < ApplicationMailer
  helper SopladosHelper

  RECIPIENTS = %w[
    geraldinne.martinez@meloncementos.cl
    pedro.guzman@meloncementos.cl
    jose.jerez@msindustrial.cl
    alejandro.olivares@msindustrial.cl
    simon.rojas@msindustrial.cl
    fernando.gonzalez@msindustrial.cl
    guillermo.roco@meloncementos.cl
    jefesturno.planta@melon.cl
    supervisor.envasadora@msindustrial.cl
    marianelly.villarroel@meloncementos.cl
    gerardo.mahana@meloncementos.cl
    maryorie.fajardo@msindustrial.cl
  ].freeze

  def report(record)
    registered_at = record.created_at.in_time_zone(Soplado::ZONE)
    @soplados = Soplado.where("created_at < :time OR (created_at = :time AND id <= :id)", time: record.created_at, id: record.id)
      .order(created_at: :desc, id: :desc).limit(4)
    recipients = RECIPIENTS.dup
    recipients << "helmut.brandau@meloncementos.cl" if (5...10).cover?(registered_at.hour)

    mail(to: recipients, subject: "Reporte Soplado TC · #{registered_at.strftime('%d/%m/%Y %H:%M')}")
  end
end
