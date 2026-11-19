class HaverDailyMailer < ApplicationMailer
  helper EnvasadoraDashboardHelper

  TO = "camila.ramirez@meloncementos.cl"
  CC = %w[
    gaston.guerrero@meloncementos.cl
    marcelo.lopez@meloncementos.cl
    orlando.vasquez@meloncementos.cl
    cristian.sotomayor@meloncementos.cl
    joanny.toledo@meloncementos.cl
    geraldinne.martinez@meloncementos.cl
    jose.jerez@msindustrial.cl
    fernando.gonzalez@msindustrial.cl
    supervisor.envasadora@msindustrial.cl
    mauricio.collado@msindustrial.cl
    leandro.estrella@msindustrial.cl
    jefesturno.planta@meloncementos.cl
  ].freeze
  TEST_RECIPIENTS = %w[jose.jerez@msindustrial.cl fernando.gonzalez@msindustrial.cl].freeze

  def report(scheduled_at:, test: false)
    @report = HaverDailyReport.new(scheduled_at: scheduled_at)
    @cutoff_label = @report.cutoff.strftime("%d/%m/%Y %H:%M")
    @test = test
    @title = "Informe diario Haver · La Calera"
    subject = "#{@title} · #{@cutoff_label}"
    subject = "PRUEBA · #{subject}" if test
    mail(to: test ? TEST_RECIPIENTS : TO, cc: test ? [] : CC, subject: subject)
  end
end
