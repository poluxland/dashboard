class MantencionMailer < ApplicationMailer
  DEFAULT_RECIPIENTS = %w[
    jose.jerez@msindustrial.cl
    julio.alvear@msindustrial.cl
    fernando.gonzalez@msindustrial.cl
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
