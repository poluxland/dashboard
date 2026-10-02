class ShiftReportMailer < ApplicationMailer
  def closing_report(report)
    @report = report
    attachments.inline["impromaq-logo.png"] = {
      mime_type: "image/png",
      content: File.binread(Rails.root.join("app/assets/images/impromaq-logo.png"))
    }
    mail(to: ShiftReport::RECIPIENTS, reply_to: report.signer_email,
      subject: "Cierre de turno sin novedades · #{report.date.strftime('%d-%m-%Y')} · #{report.shift}")
  end
end
