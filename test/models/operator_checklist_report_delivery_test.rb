require "test_helper"

class OperatorChecklistReportDeliveryTest < ActiveSupport::TestCase
  test "reports are sent once per slot and start with the first eligible slot after activation" do
    zone = Time.find_zone!("America/Santiago")
    start = zone.local(2026, 11, 19, 6, 1)
    settings = { start_at: start.iso8601, ptm_utc_time: "12:00" }

    assert_no_difference "ActionMailer::Base.deliveries.size" do
      OperatorChecklistReportDelivery.dispatch_due(reference_time: start, **settings)
      OperatorChecklistReportDelivery.dispatch_due(reference_time: Time.utc(2026, 11, 19, 11, 59), **settings)
    end

    ptm = Time.utc(2026, 11, 19, 12)
    lca = zone.local(2026, 11, 19, 14)
    assert_difference "ActionMailer::Base.deliveries.size", 2 do
      [ ptm, ptm + 1.minute, lca + 1.minute, lca + 2.minutes ].each do |time|
        OperatorChecklistReportDelivery.dispatch_due(reference_time: time, **settings)
      end
    end

    assert OperatorChecklistReportDelivery.find_by!(plant: "PTM", scheduled_at: ptm).sent_at?
    assert OperatorChecklistReportDelivery.find_by!(plant: "LCA", scheduled_at: lca).sent_at?
  end

  test "La Calera uses Chilean clock time during summer and winter" do
    { 1 => 9, 7 => 10 }.each do |month, utc_hour|
      cutoff = Time.utc(2026, month, 19, utc_hour)
      slots = OperatorChecklistReportDelivery.scheduled_slots(cutoff, nil)
      assert_includes slots, [ "LCA", cutoff ]
      assert_equal [ 6, 14, 22 ], slots.select { |_, time| time.day == 19 }.map { |_, time| time.hour }
    end
  end
end
