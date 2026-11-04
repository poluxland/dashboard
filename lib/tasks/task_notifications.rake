namespace :tasks do
  desc "Send pending assignment and due-date notifications"
  task notify: :environment do
    TaskNotification.dispatch_pending
  end

  desc "Continuously deliver durable task notifications"
  task notification_worker: :environment do
    loop do
      begin
        TaskNotification.dispatch_pending
      rescue StandardError => error
        Rails.logger.error("Task notification worker failed: #{error.class}")
      end
      sleep 60
    end
  end
end
