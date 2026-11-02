class EnvasadoraReportMailer < ApplicationMailer
  helper EnvasadoraReportsHelper

  def report(report, internal: false)
    @report = report
    mail(to: internal ? EnvasadoraReport::INTERNAL_RECIPIENTS : report.recipients, subject: "Reporte envasadora — #{report.date} — #{report.turno}")
  end
end
