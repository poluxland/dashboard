class EnvasadoraReportMailer < ApplicationMailer
  helper EnvasadoraReportsHelper

  def report(report)
    @report = report
    mail(to: report.recipients, subject: "PRUEBA Reporte envasadora — #{report.date} — #{report.turno}")
  end
end
