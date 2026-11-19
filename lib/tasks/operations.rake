namespace :operations do
  desc "Envía el informe semanal de operaciones PTM el lunes (hora de Chile)"
  task send_weekly_report: :environment do
    today = OperationWeeklyReport.local_today
    next unless today.monday?

    recipients = ENV.fetch("OPERATIONS_REPORT_RECIPIENTS", "").split(/[\s,;]+/).reject(&:blank?).uniq
    abort "Configura OPERATIONS_REPORT_RECIPIENTS para enviar el informe semanal de operaciones." if recipients.empty?

    OperationActivityMailer.weekly_report(recipients: recipients, week_of: today - 1.week).deliver_now
    puts "Informe semanal de operaciones enviado."
  end
end
