namespace :tasks do
  desc "Send pending assignment and due-date notifications"
  task notify: :environment do
    TaskNotification.dispatch_pending
  end

  desc "Continuously deliver durable task notifications"
  task notification_worker: :environment do
    loop do
      begin
        HaverDailyDelivery.dispatch_due
      rescue StandardError => error
        Rails.logger.error("Daily Haver report delivery failed: #{error.class}")
      end
      begin
        TaskNotification.dispatch_pending
      rescue StandardError => error
        Rails.logger.error("Task notification worker failed: #{error.class}")
      end
      begin
        OperationWeeklyDelivery.dispatch_due
      rescue StandardError => error
        Rails.logger.error("Operations weekly report delivery failed: #{error.class}")
      end
      begin
        OperatorChecklistReportDelivery.dispatch_due
      rescue StandardError => error
        Rails.logger.error("Operator checklist report scheduler failed: #{error.class}")
      end
      begin
        OvertimeReportDelivery.dispatch_due
      rescue StandardError => error
        Rails.logger.error("Overtime report scheduler failed: #{error.class}")
      end
      begin
        PmmTruckReportDelivery.dispatch_due
      rescue StandardError => error
        Rails.logger.error("PMM truck report scheduler failed: #{error.class}")
      end
      sleep 60
    end
  end
end
