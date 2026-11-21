class OvertimeMailer < ApplicationMailer
  helper OvertimeEntriesHelper

  def login_code(email:, code:)
    @code = code
    mail(to: email, subject: "Código de acceso a Horas extra")
  end

  def pending_report(recipient:)
    @entries = OvertimeAccess.entries_for(recipient).pending_review.order(:fecha, :id).to_a
    @by_mandante = @entries.group_by(&:mandante)
    options = Rails.env.production? ? { host: ENV.fetch("OVERTIME_MAIL_HOST", "msindustrial.cl"), protocol: "https" } : {}
    @review_url = overtime_entries_url(**options)
    mail(to: recipient, subject: "Horas extras pendientes de revisión PTM")
  end
end
