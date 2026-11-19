namespace :operations do
  desc "Envía el informe semanal de operaciones PTM si está pendiente (lunes desde las 08:00 de Chile)"
  task send_weekly_report: :environment do
    week = ENV["OPERATIONS_REPORT_WEEK"].presence
    sent_at = if week
      OperationWeeklyDelivery.dispatch_week(week_of: Date.iso8601(week))
    else
      OperationWeeklyDelivery.dispatch_due
    end
    puts "Informe semanal de operaciones enviado." if sent_at
  end
end
