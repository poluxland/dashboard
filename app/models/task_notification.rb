class TaskNotification < ApplicationRecord
  belongs_to :task

  def deliver!
    with_lock do
      return if sent_at?
      # Obsolete reminders and assignments must not reach a previous assignee.
      if recipient != task.assignee_email || (kind == "due" && (task.status == "done" || task.due_on != due_on))
        update!(sent_at: Time.current)
        return
      end
      TaskMailer.notice(self).deliver_now
      update!(sent_at: Time.current)
    end
  end

  def self.dispatch_pending
    local_time = Time.current.in_time_zone("America/Santiago")
    today = local_time.to_date
    Task.where(due_on: today).where.not(status: "done").find_each do |task|
      next if local_time.hour < 8

      find_or_create_by!(deduplication_key: "due:#{task.id}:#{today}:#{task.assignee_email}") do |notice|
        notice.task = task
        notice.kind = "due"
        notice.recipient = task.assignee_email
        notice.due_on = today
      end
    end
    where(sent_at: nil).find_each do |notice|
      begin
        notice.deliver!
      rescue StandardError => error
        Rails.logger.error("Task notification #{notice.id} failed: #{error.class}")
      end
    end
  end
end
