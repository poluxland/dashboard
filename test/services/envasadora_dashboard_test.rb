require "test_helper"

class EnvasadoraDashboardTest < ActiveSupport::TestCase
  setup do
    @import = TptImport.create!(filename: "test.xlsx", author_email: "test@msindustrial.cl")
    @date = Date.new(2026, 10, 15)
    # Test schedule only; production schedule is supplied by the application.
    @shift_starts = { "TN" => -2, "TM" => 6, "TT" => 14 }
  end

  def report(date: @date, shift: "TM", production: 100, hours: 2)
    measurements = EnvasadoraReport::SILOS.values.flat_map { |silo| silo[:readings] }.index_with { 10 }
    EnvasadoraReport.create!(measurements.merge(date: date, turno: shift, prodhaver: production, prodvento: 50,
                                               horas_haver: hours, horas_vento: 1, author_email: "test@msindustrial.cl"))
  end

  def event(at:, seconds:, impact: "Parada no planificada", reason: "Cintas Haver")
    @import.tpt_events.create!(source_row: 11, started_at: at, duration_seconds: seconds, impact: impact,
                               production_state: impact == "Correr" ? "Corriendo" : "Abajo", reason: reason,
                               source_fingerprint: SecureRandom.hex)
  end

  def dashboard(params = {})
    EnvasadoraDashboard.new({ from: @date.iso8601, to: @date.iso8601 }.merge(params), shift_starts: @shift_starts, default_source: "haver").call
  end

  test "uses latest report per date and shift without adding inventory or other machines" do
    report(production: 900)
    latest = report(production: 120)
    result = dashboard
    assert_equal 120, result.production_total
    assert_equal 1, result.production_shift_count
    assert_equal 1, result.duplicate_report_count
    assert_equal latest, result.rows.sole[:report]
    assert_equal 60, result.production_per_hour
    assert_nil result.availability
    assert_equal 170, dashboard(source: "ambas").production_total
    assert_equal 50, dashboard(source: "vento").production_total
  end

  test "splits events at shift boundaries and midnight and counts each failure once" do
    %w[TM TT TN].each { |shift| report(shift: shift) }
    event(at: Time.utc(2026, 10, 15, 13, 30), seconds: 3600)
    event(at: Time.utc(2026, 10, 14, 23, 30), seconds: 3600, reason: "Rotativa")
    result = dashboard
    assert_equal 3, result.rows.size
    assert_in_delta 30, result.rows.find { |row| row[:shift] == "TM" }[:downtime_seconds] / 60
    assert_in_delta 30, result.rows.find { |row| row[:shift] == "TT" }[:downtime_seconds] / 60
    assert_in_delta 60, result.rows.find { |row| row[:shift] == "TN" }[:downtime_seconds] / 60
    assert_equal 2, result.pareto.sum { |row| row[:events] }
    assert_in_delta 60, result.mttr
  end

  test "clips events to selected shifts and dates and excludes negatives" do
    report
    event(at: Time.utc(2026, 10, 15, 5, 30), seconds: 7200)
    event(at: Time.utc(2026, 10, 15, 7), seconds: -1)
    result = dashboard(shifts: [ "TM" ])
    assert_in_delta 90, result.mttr
    assert_equal 1, result.negative_count
    assert_equal 1, result.rows.sole[:event_count]
    assert_empty dashboard(weekdays: [ "1" ]).rows
  end

  test "availability uses observed scheduled intervals and does not treat missing coverage as running" do
    report
    event(at: Time.utc(2026, 10, 15, 6), seconds: 3600, impact: "Correr", reason: "Running Normally")
    event(at: Time.utc(2026, 10, 15, 7), seconds: 1800)
    event(at: Time.utc(2026, 10, 15, 7, 15), seconds: 1800)
    event(at: Time.utc(2026, 10, 15, 7, 45), seconds: 900, impact: "No programada", reason: "Colación")
    result = dashboard
    assert_in_delta 100.0 * 60 / 105, result.availability
    assert_in_delta 30.0 / 60, result.mtbf
    assert_in_delta 22.5, result.mttr
    assert_in_delta 25, result.rows.sole[:coverage]
    assert_in_delta 45, result.rows.sole[:downtime_seconds] / 60
    included = dashboard(exclude_unscheduled: "0")
    assert_in_delta 60, included.rows.sole[:downtime_seconds] / 60
    assert_in_delta result.availability, included.availability
  end

  test "preserves missing versus zero production in tables and averages" do
    report(production: 0)
    event(at: Time.utc(2026, 10, 15, 15), seconds: 600)
    result = dashboard
    assert_equal 0, result.production_total
    assert_equal 1, result.production_shift_count
    assert_nil result.rows.find { |row| row[:shift] == "TT" }
    assert_equal 0, result.tpt_only_count
    assert_equal 1, result.production_only_count
    assert_equal 0, result.charts[:weekday][:datasets].find { |series| series[:label] == "TM" }[:data][3]
    assert_nil result.charts[:weekday][:datasets].find { |series| series[:label] == "TT" }[:data][3]
  end

  test "does not inflate production per hour when some producing shifts lack hours" do
    report(shift: "TM", production: 100, hours: 2)
    report(shift: "TT", production: 200, hours: 0)
    result = dashboard
    assert_equal 300, result.production_total
    assert_equal 1, result.missing_hours_count
    assert_nil result.production_per_hour
  end

  test "excludes Missing Reason by default from all TPT aggregates and restores it on request" do
    report(production: 100)
    event(at: Time.utc(2026, 10, 15, 6), seconds: 3600, impact: "Correr", reason: "Running Normally")
    event(at: Time.utc(2026, 10, 15, 7), seconds: 1800, reason: "Cintas Haver")
    event(at: Time.utc(2026, 10, 15, 7, 30), seconds: 3600, reason: " Missing reason ")
    excluded = dashboard
    included = dashboard(include_missing_reason: "1")
    assert_not excluded.include_missing_reason
    assert included.include_missing_reason
    assert_equal 100, excluded.production_total
    assert_equal excluded.production_total, included.production_total
    assert_equal 1, excluded.rows.sole[:event_count]
    assert_equal 2, included.rows.sole[:event_count]
    assert_in_delta 90 * 60, excluded.rows.sole[:observed_seconds]
    assert_in_delta 150 * 60, included.rows.sole[:observed_seconds]
    assert_in_delta 100.0 * 60 / 90, excluded.availability
    assert_in_delta 40, included.availability
    assert_in_delta 1, excluded.mtbf
    assert_in_delta 0.5, included.mtbf
    assert_in_delta 30, excluded.mttr
    assert_in_delta 45, included.mttr
    assert_equal [ "Cintas Haver" ], excluded.charts[:pareto][:labels]
    assert_includes included.charts[:pareto][:labels], " Missing reason "
    assert_in_delta 30, dashboard(include_missing_reason: "0").pareto.sole[:minutes]
    assert_equal 3, @import.tpt_events.count
  end

  test "pareto retains remaining causes as Others and cumulative totals reconcile" do
    report
    7.times { |number| event(at: Time.utc(2026, 10, 15, 8) + number * 60, seconds: 60, reason: "Razón #{number}") }
    result = dashboard(top: "5")
    assert_equal 6, result.pareto.size
    assert_equal "Otros (2)", result.pareto.last[:label]
    assert_in_delta 7, result.pareto.sum { |row| row[:minutes] }
    assert_in_delta 100, result.pareto.last[:cumulative]
  end

  test "counts only portions overlapping reported shifts without changing the source event" do
    report(shift: "TM")
    report(shift: "TN")
    @shift_starts = { "TN" => 22, "TM" => 6, "TT" => 14 }
    original = event(at: Time.utc(2026, 10, 15, 13, 30), seconds: 9.hours)
    result = dashboard
    assert_equal %w[TN TM], result.rows.map { |row| row[:shift] }
    assert_equal 0, result.tpt_only_count
    assert_in_delta 3600, result.rows.sum { |row| row[:observed_seconds] }
    assert_in_delta 60, result.pareto.sole[:minutes]
    assert_equal 1, result.pareto.sole[:events]
    assert_in_delta 60, result.mttr
    assert_equal 9.hours, original.reload.duration_seconds
    assert_equal 1, @import.tpt_events.count
  end

  test "rejects invalid dates and reversed periods" do
    assert_raises(EnvasadoraDashboard::InvalidFilter) { dashboard(from: "2026-02-30") }
    assert_raises(EnvasadoraDashboard::InvalidFilter) { dashboard(from: "2026-10-16", to: "2026-10-15") }
  end

  test "TN belongs to start date and Saturday TM coverage uses six programmed hours" do
    report(shift: "TN")
    report(date: Date.new(2026, 10, 17), shift: "TM")
    schedule = { "TN" => 22, "TM" => 6, "TT" => 14 }
    event(at: Time.utc(2026, 10, 16, 1), seconds: 3600)
    result = EnvasadoraDashboard.new({ from: "2026-10-15", to: "2026-10-15", shifts: [ "TN" ] }, shift_starts: schedule, default_source: "haver").call
    assert_equal @date, result.rows.sole[:date]
    assert_equal "TN", result.rows.sole[:shift]
    event(at: Time.utc(2026, 10, 17, 6), seconds: 8.hours, impact: "Correr", reason: "Running Normally")
    saturday = EnvasadoraDashboard.new({ from: "2026-10-17", to: "2026-10-17" }, shift_starts: schedule, default_source: "haver").call
    assert_equal 6, saturday.rows.sole[:planned_hours]
    assert_equal 100, saturday.rows.sole[:coverage]
    assert_equal 100, saturday.availability
    event(at: Time.utc(2026, 10, 17, 12), seconds: 3600)
    after_schedule = EnvasadoraDashboard.new({ from: "2026-10-17", to: "2026-10-17" }, shift_starts: schedule, default_source: "haver").call
    assert_nil after_schedule.mttr
    assert_equal 100, after_schedule.availability
  end
end
