require "test_helper"

class PtmHistoryImporterTest < ActiveSupport::TestCase
  def rows
    [
      { "row" => 2, "date" => "2026-10-01", "shift" => "TN", "equipment" => "Rotopakcer ", "minutes" => 30 },
      { "row" => 3, "date" => "2026-10-01", "equipment" => "Termino turno", "minutes" => 20, "production" => 1000 },
      { "row" => 4, "date" => "2026-10-01", "shift" => "TM", "equipment" => "Inicio de  turno", "minutes" => 10, "production" => 2000 }
    ]
  end

  test "inherits shifts normalizes equipment preserves source and imports only once" do
    result = PtmHistoryImporter.new(rows).call
    assert_equal 2, result[:imported]
    report = PtmReport.find_by!(date: "2026-10-01", shift: "TN")
    assert_equal 1000, report.production
    assert_equal 2, report.ptm_events.size
    assert_equal "Rotopacker", report.ptm_events.first.equipment
    assert_equal "Rotopakcer ", report.ptm_events.first.original_equipment
    assert_equal rows.first(2), report.source_rows
    assert_no_difference "PtmEvent.count" do
      assert_equal 2, PtmHistoryImporter.new(rows).call[:existing]
    end
  end

  test "ambiguous production and excessive minutes are preserved for review" do
    data = rows
    data[0]["production"] = 200
    data[0]["minutes"] = 480
    PtmHistoryImporter.new(data).call
    report = PtmReport.find_by!(shift: "TN")
    assert_nil report.production
    assert_not report.usable_times?
    assert_match "Varias producciones", report.review_notes
    totals = PtmDashboard.new("all").totals
    assert_equal 50, totals[:tons]
    assert_equal 1, totals[:coverage]
    assert_in_delta 97.9167, totals[:available], 0.001
  end

  test "dry run does not persist and invalid rows roll back entire import" do
    assert_no_difference "PtmReport.count" do
      PtmHistoryImporter.new(rows).call(dry_run: true)
    end
    data = rows
    data.last["minutes"] = -1
    assert_no_difference "PtmReport.count" do
      assert_raises(ActiveRecord::RecordInvalid) { PtmHistoryImporter.new(data).call }
    end
  end

  test "future records are retained for review but excluded from charts" do
    PtmReport.create!(date: Date.current + 2, shift: "TM", production: 1000, author_email: "import",
      source_key: "future", review_notes: "Fecha por revisar")
    assert_empty PtmDashboard.new("month").reports
    assert_equal 1, PtmDashboard.new("month").review_reports.size
  end

  test "manual records validate durations and use eight hour shifts" do
    report = PtmReport.new(date: Date.current, shift: "TM", production: 1000, author_email: "test@example.com")
    report.ptm_events.build(equipment: "Radimat", minutes: 481)
    assert_not report.valid?
    report.ptm_events.first.minutes = 60
    report.save!
    totals = PtmDashboard.new("all").totals
    assert_equal 25, totals[:tons]
    assert_equal 3.125, totals[:rate]
    assert_equal 87.5, totals[:available]
  end
end
