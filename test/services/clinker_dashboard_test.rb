require "test_helper"

class ClinkerDashboardTest < ActiveSupport::TestCase
  test "weekly totals keep missing days distinct from zero and trend uses calendar days" do
    travel_to Time.zone.local(2026, 11, 17, 12) do
      [ 1291, 943, 1236, 1377, 1551, 401 ].each_with_index do |tons, index|
        ClinkerTransfer.create!(date: Date.new(2026, 11, 9) + index, tons: tons, author_email: "initial")
      end
      report = ClinkerDashboard.new("previous_week")
      assert_equal Date.new(2026, 11, 9), report.from
      assert_equal Date.new(2026, 11, 15), report.to
      assert_equal 6799, report.total
      assert_in_delta 1133.1667, report.average, 0.001
      assert_equal 1, report.missing_days
      assert_nil report.charts[:days].last[:tons]
      assert_nil report.charts[:days].last[:average]
      assert_equal 6799, report.charts[:weeks].first[:tons]
      assert_equal 1551, report.peak.tons
      ClinkerTransfer.create!(date: Date.new(2026, 11, 15), tons: 0, author_email: "initial")
      assert_equal 0, ClinkerDashboard.new("previous_week").charts[:days].last[:tons]
      assert_in_delta 971.2857, ClinkerDashboard.new("previous_week").average, 0.001
    end
  end

  test "rolling average includes prior days outside selected period and validates daily records" do
    travel_to Time.zone.local(2026, 11, 17, 12) do
      ClinkerTransfer.create!(date: Date.new(2026, 11, 10), tons: 100, author_email: "initial")
      ClinkerTransfer.create!(date: Date.new(2026, 11, 11), tons: 200, author_email: "initial")
      assert_equal 150, ClinkerDashboard.new("7").charts[:days].first[:average]
      assert_not ClinkerTransfer.new(date: Date.new(2026, 11, 10), tons: 0, author_email: "user").valid?
      assert_not ClinkerTransfer.new(date: Date.current + 1, tons: 2, author_email: "user").valid?
      assert_not ClinkerTransfer.new(date: Date.current, tons: -1, author_email: "user").valid?
    end
  end
end
