namespace :haver do
  desc "Deliver the weekday Haver report if the Chilean morning slot is due"
  task dispatch_daily: :environment do
    delivered_at = HaverDailyDelivery.dispatch_due
    puts delivered_at ? "Informe Haver enviado." : "Sin envío Haver pendiente en este horario."
  end
end
