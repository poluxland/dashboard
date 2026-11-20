class HaverDailyMailer < ApplicationMailer
  helper EnvasadoraDashboardHelper

  TO = "camila.ramirez@meloncementos.cl"
  CC = %w[
    guillermo.roco@meloncementos.cl
    gaston.guerrero@meloncementos.cl
    marcelo.lopez@meloncementos.cl
    orlando.vasquez@meloncementos.cl
    cristian.sotomayor@meloncementos.cl
    joanny.toledo@meloncementos.cl
    geraldinne.martinez@meloncementos.cl
    jose.jerez@msindustrial.cl
    fernando.gonzalez@msindustrial.cl
    claudio.villanueva@msindustrial.cl
    supervisor.envasadora@msindustrial.cl
    mauricio.collado@msindustrial.cl
    leandro.estrella@msindustrial.cl
    jefesturno.planta@meloncementos.cl
  ].freeze
  TEST_RECIPIENTS = %w[
    jose.jerez@msindustrial.cl fernando.gonzalez@msindustrial.cl claudio.villanueva@msindustrial.cl
  ].freeze
  PRODUCTION_CHART_FILENAME = "haver-produccion-rendimiento.png"
  PARETO_CHART_FILENAME = "haver-pareto-detenciones.png"

  def report(scheduled_at:, test: false)
    @report = HaverDailyReport.new(scheduled_at: scheduled_at)
    @cutoff_label = @report.cutoff.strftime("%d/%m/%Y %H:%M")
    @test = test
    @title = "Informe diario Haver · La Calera"
    @production_chart_url = attach_chart(PRODUCTION_CHART_FILENAME, HaverEmailChart.production(@report.production_by_day))
    @pareto_chart_url = attach_chart(PARETO_CHART_FILENAME, HaverEmailChart.pareto(@report.pareto_causes))
    subject = "#{@title} · #{@cutoff_label}"
    subject = "PRUEBA · #{subject}" if test
    mail(to: test ? TEST_RECIPIENTS : TO, cc: test ? [] : CC, subject: subject)
  end

  private

  def attach_chart(filename, image)
    return unless image

    attachments.inline[filename] = { mime_type: "image/png", content: image }
    attachments[filename].url
  end
end
