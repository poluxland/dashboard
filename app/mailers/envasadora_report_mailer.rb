class EnvasadoraReportMailer < ApplicationMailer
  def report(report)
    @report = report
    mail(to: report.recipients, subject: "Reporte envasadora — #{report.date} — #{report.turno}")
  end
end
