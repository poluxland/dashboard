class MantencionMailer < ApplicationMailer
  DEFAULT_RECIPIENTS = %w[
    jose.jerez@msindustrial.cl
    julio.alvear@msindustrial.cl
    fernando.gonzalez@msindustrial.cl
    martin.llancafil@meloncementos.cl
    daniel.garrido@meloncementos.cl
    francisco.salgado@meloncementos.cl
    gerardo.martinez@meloncementos.cl
    johnny.rute@meloncementos.cl
    camila.birke@msindustrial.cl
    juan.belmar@meloncementos.cl
    manuel.sepulveda@meloncementos.cl
    alex.rioseco@meloncementos.cl
    gabriel.arancibia@meloncementos.cl
    alex.dorante@msindustrial.cl
    mario.santibanez@meloncementos.cl
    maximiliano.perez@meloncementos.cl
    efrain.mindiola@meloncementos.cl
    hector.ampuero@msindustrial.cl
    luis.navas@msindustrial.cl
    isabel.tapia@meloncementos.cl
    jose.opazo-externo@melonservicios.cl
    gari.aguilera@meloncementos.cl
    pia.villegas@meloncementos.cl
    carolina.vera@meloncementos.cl
    moira.cisternas@meloncementos.cl
    exequiel.moya@msindustrial.cl
    rodrigo.bravo@meloncementos.cl
    hans.velasquez@msindustrial.cl
    helmut.brandau@meloncementos.cl
  ].freeze

  def weekly_report(reference_date: MantencionWeeklyReport.local_today)
    @report = MantencionWeeklyReport.new(reference_date: reference_date)

    mail(
      to: recipients,
      subject: "Informe semanal de mantenciones · Semana #{@report.week_number}"
    )
  end

  private

  def recipients
    ENV.fetch("MANTENCIONES_REPORT_RECIPIENTS", DEFAULT_RECIPIENTS.join(","))
      .split(/[\s,;]+/)
      .filter_map(&:presence)
      .uniq
  end
end
