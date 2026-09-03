class MantencionMailer < ApplicationMailer
  DEFAULT_RECIPIENT = "jose.jerez@msindustrial.cl"

  def weekly_report(reference_date: MantencionWeeklyReport.local_today)
    @report = MantencionWeeklyReport.new(reference_date: reference_date)

    mail(
      to: recipients,
      subject: "Informe semanal de mantenciones · Semana #{@report.week_number}"
    )
  end

  private

  def recipients
    ENV.fetch("MANTENCIONES_REPORT_RECIPIENTS", DEFAULT_RECIPIENT)
      .split(/[\s,;]+/)
      .filter_map(&:presence)
      .uniq
  end
end
