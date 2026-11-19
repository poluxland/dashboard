class OperatorChecklistMailer < ApplicationMailer
  COMMON_RECIPIENTS = %w[
    jose.jerez@msindustrial.cl
    simon.rojas@msindustrial.cl
    marcos.prospero@msindustrial.cl
    supervisor.envasadora@msindustrial.cl
    maryorie.fajardo@msindustrial.cl
  ].freeze

  RECIPIENTS = {
    "LCA" => (COMMON_RECIPIENTS + %w[fernando.gonzalez@msindustrial.cl]).freeze,
    "PTM" => (COMMON_RECIPIENTS + %w[
      julio.alvear@msindustrial.cl
      victor.gallardo@msindustrial.cl
      pedro.pichaud@msindustrial.cl
      exequiel.moya@msindustrial.cl
      fernando.gonzalez@msindustrial.cl
    ]).freeze
  }.freeze

  def report(plant:, scheduled_at:)
    @report = OperatorChecklistReport.new(plant: plant, scheduled_at: scheduled_at)
    @rows = @report.rows
    @title = "Checklist de operador · #{@report.plant_name}"
    @period = if plant == "LCA"
      "#{@report.window.begin.strftime('%d/%m/%Y %H:%M')} a #{@report.window.end.strftime('%d/%m/%Y %H:%M')}"
    else
      @report.window.begin.strftime("%d/%m/%Y")
    end

    mail(to: RECIPIENTS.fetch(plant), subject: "#{@title} · #{@period}")
  end
end
