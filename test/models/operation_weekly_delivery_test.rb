require "test_helper"

class OperationWeeklyDeliveryTest < ActiveSupport::TestCase
  test "el informe se envía una vez el lunes a partir de las ocho en Chile" do
    recipients_key = "OPERATIONS_REPORT_RECIPIENTS"
    previous_recipients = ENV[recipients_key]
    ENV[recipients_key] = "operaciones@example.com, operaciones@example.com"
    zone = Time.find_zone!("America/Santiago")

    assert_no_difference "ActionMailer::Base.deliveries.size" do
      OperationWeeklyDelivery.dispatch_due(reference_time: zone.local(2026, 11, 22, 8))
      OperationWeeklyDelivery.dispatch_due(reference_time: zone.local(2026, 11, 23, 7, 59))
    end
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      OperationWeeklyDelivery.dispatch_due(reference_time: zone.local(2026, 11, 23, 8))
      OperationWeeklyDelivery.dispatch_due(reference_time: zone.local(2026, 11, 23, 8, 1))
    end
    email = ActionMailer::Base.deliveries.last
    assert_equal [ "operaciones@example.com" ], email.to
    assert_equal "Informe semanal de operaciones · Semana 47", email.subject
    assert OperationWeeklyDelivery.find_by!(week_start: Date.new(2026, 11, 16)).sent_at?
  ensure
    ENV[recipients_key] = previous_recipients
  end
end
