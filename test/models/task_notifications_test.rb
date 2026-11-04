require "test_helper"

class TaskNotificationsTest < ActiveSupport::TestCase
  setup do
    ActionMailer::Base.deliveries.clear
    @task = Task.create!(title: "Revisar guardas", description: "Inspeccionar y registrar resultados", assignee_email: "usuario@msindustrial.cl", creator_email: "fernando.gonzalez@msindustrial.cl", category: "safety", plant: "LCA", items_attributes: [ { title: "Inspección", due_on: Date.new(2026, 11, 4) } ])
  end

  test "assignment is durable and mail includes details and checklist" do
    notice = @task.notifications.sole
    notice.deliver!
    notice.deliver!
    assert_equal 1, ActionMailer::Base.deliveries.size
    mail = ActionMailer::Base.deliveries.last
    assert_equal [ @task.assignee_email ], mail.to
    assert_includes mail.html_part.body.decoded, "Seguridad"
    assert_includes mail.html_part.body.decoded, "LCA"
    assert_includes mail.text_part.body.decoded, "Inspección"
    assert_includes mail.text_part.body.decoded, "/tasks/#{@task.id}"
  end

  test "reminder runs after eight Chile time and only once for open due tasks" do
    @task.notifications.update_all(sent_at: Time.current)
    @task.update!(due_on: Date.new(2026, 11, 4))
    travel_to Time.utc(2026, 11, 4, 10) do
      TaskNotification.dispatch_pending
      assert_empty ActionMailer::Base.deliveries
    end
    travel_to Time.utc(2026, 11, 4, 11) do
      TaskNotification.dispatch_pending
      TaskNotification.dispatch_pending
      assert_equal 1, ActionMailer::Base.deliveries.size
      assert_includes ActionMailer::Base.deliveries.last.subject, "Vence hoy"
    end
  end

  test "completed tasks receive no reminder and obsolete recipients get no mail" do
    @task.update!(assignee_email: "nuevo@msindustrial.cl", due_on: Date.new(2026, 11, 4), status: "done")
    travel_to(Time.utc(2026, 11, 4, 12)) { TaskNotification.dispatch_pending }
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal [ "nuevo@msindustrial.cl" ], ActionMailer::Base.deliveries.last.to
    assert_empty @task.notifications.where(kind: "due")
  end

  test "invalid nested checklist rolls back task and notification" do
    assert_no_difference([ "Task.count", "TaskNotification.count" ]) do
      task = Task.new(title: "Invalid", assignee_email: @task.assignee_email, creator_email: @task.creator_email, items_attributes: [ { title: "Missing date" } ])
      assert_not task.save
    end
  end
end
