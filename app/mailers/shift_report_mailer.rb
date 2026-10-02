class ShiftReportMailer < ApplicationMailer
  def closing_report(report)
    @report = report
    mail(to: ShiftReport::RECIPIENTS, reply_to: report.signer_email,
      subject: "Cierre de turno sin novedades · #{report.date.strftime('%d-%m-%Y')} · #{report.shift}")
  end
end
