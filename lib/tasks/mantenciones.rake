namespace :mantenciones do
  desc "Envía el informe semanal de mantenciones (el Scheduler debe ejecutarlo diariamente)"
  task send_weekly_report: :environment do
    today = MantencionWeeklyReport.local_today
    forced = ActiveModel::Type::Boolean.new.cast(ENV["FORCE_WEEKLY_REPORT"])

    unless today.monday? || forced
      puts "Informe semanal omitido: hoy no es lunes en America/Santiago."
      next
    end

    MantencionMailer.weekly_report(reference_date: today).deliver_now
    puts "Informe semanal de mantenciones enviado para la semana anterior."
  end
end
