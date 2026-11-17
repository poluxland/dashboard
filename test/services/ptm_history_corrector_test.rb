require "test_helper"

class PtmHistoryCorrectorTest < ActiveSupport::TestCase
  test "fills missing minutes with one and caps remaining times exactly at 480" do
    report = PtmReport.create!(date: Date.current, shift: "TN", author_email: "import", source_key: "test",
      review_notes: "Detenciones superiores a 480 minutos. Hay detenciones sin minutos informados.")
    [ 400, 200, nil ].each { |minutes| report.ptm_events.create!(equipment: "Radimat", minutes: minutes) }
    result = PtmHistoryCorrector.new.call
    assert_equal 1, result[:capped_shifts]
    assert_equal 1, result[:filled_minutes]
    report.reload
    assert_equal 480, report.stopped_minutes
    assert_equal 1, report.ptm_events.order(:id).last.minutes
    assert_equal [ BigDecimal("319.33"), BigDecimal("159.67"), BigDecimal("1") ], report.ptm_events.order(:id).map(&:minutes)
    assert report.usable_times?
    assert_nil report.history_adjustments["times_v1"]["original_minutes"].values.last
    assert_equal({ capped_shifts: 0, filled_minutes: 0, moved_productions: 0, production_conflicts: [] }, PtmHistoryCorrector.new.call)
  end

  test "moves excess production to the next shift and never overwrites an occupied shift" do
    rows = [
      { "row" => 2, "date" => "2026-10-01", "shift" => "TN", "equipment" => "Radimat", "minutes" => 20, "production" => 100 },
      { "row" => 3, "date" => "2026-10-01", "equipment" => "Radimat", "minutes" => 20, "production" => 200 },
      { "row" => 4, "date" => "2026-10-01", "shift" => "TT", "equipment" => "Radimat", "minutes" => 20, "production" => 300 },
      { "row" => 5, "date" => "2026-10-01", "equipment" => "Radimat", "minutes" => 20, "production" => 400 },
      { "row" => 6, "date" => "2026-10-02", "shift" => "TN", "equipment" => "Radimat", "minutes" => 20, "production" => 500 }
    ]
    PtmHistoryImporter.new(rows).call
    result = PtmHistoryCorrector.new.call
    assert_equal 1, result[:moved_productions]
    assert_equal 1, result[:production_conflicts].size
    assert_equal 100, PtmReport.find_by!(date: "2026-10-01", shift: "TN").production
    target = PtmReport.find_by!(date: "2026-10-01", shift: "TM")
    assert_equal 200, target.production
    assert_not target.usable_times?
    assert_equal 500, PtmReport.find_by!(date: "2026-10-02", shift: "TN").production
    assert_equal 0, PtmHistoryCorrector.new.call[:moved_productions]
    assert_equal 200, target.reload.production
    assert_equal rows.first(2), PtmReport.find_by!(date: "2026-10-01", shift: "TN").source_rows
  end

  test "does not change manually entered reports or unrelated review notes" do
    report = PtmReport.create!(date: Date.current, shift: "TN", author_email: "user")
    report.ptm_events.create!(equipment: "Radimat", minutes: 20)
    imported = PtmReport.create!(date: Date.current, shift: "TM", author_email: "import", source_key: "test",
      review_notes: "Fecha posterior a la carga original (17/11/2026).")
    PtmHistoryCorrector.new.call
    assert_empty report.reload.history_adjustments
    assert_equal 20, report.stopped_minutes
    assert_match "Fecha posterior", imported.reload.review_notes
  end
end
