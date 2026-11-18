require "test_helper"

class HaverDashboardTest < ActiveSupport::TestCase
  setup do
    @date = Date.new(2026, 11, 14)
    measurements = EnvasadoraReport::SILOS.values.flat_map { |silo| silo[:readings] }.index_with(10)
    @report = EnvasadoraReport.create!(measurements.merge(date: @date, turno: "TM", author_email: "test@msindustrial.cl", prodhaver: 8000, horas_haver: 4, sacos_rotos_haver: 80, sacos_descartados_haver: 0))
    imported = TptImport.create!(filename: "haver.xlsx", author_email: "test@msindustrial.cl")
    [ [ 6, 4, "Correr", "Running Normally" ], [ 10, 1, "Parada planificada", "Intervención o Revisión" ], [ 11, 1, "Parada no planificada", "Cintas Haver" ] ].each do |hour, duration, impact, reason|
      imported.tpt_events.create!(started_at: Time.utc(2026, 11, 14, hour), duration_seconds: duration * 3600, impact: impact, reason: reason, production_state: "Estado", source_row: hour, source_fingerprint: SecureRandom.hex)
    end
  end

  def dashboard(ideal: "50")
    HaverDashboard.new(period: "7", ideal: ideal)
  end

  test "quality subtracts broken and discarded bags from reported good production" do
    @report.update!(sacos_descartados_haver: 120, sacos_no_reconocidos_haver: 52)
    summary = dashboard.totals
    assert_equal 8000, summary[:good_bags]
    assert_equal 80, summary[:broken_bags]
    assert_equal 120, summary[:discarded_bags]
    assert_equal 52, summary[:unrecognized_bags]
    assert_equal 200, summary[:total_haver]
    assert_in_delta 97.5, summary[:quality]
    assert_in_delta 65, summary[:oee]
    @report.update!(sacos_descartados_haver: nil)
    assert_nil dashboard.totals[:quality]
    assert_equal 80, dashboard.totals[:total_haver]
    assert_equal 1, dashboard.totals[:missing_quality]
  end

  test "retains losses without good production without changing operating indicators" do
    idle = @report.dup
    idle.assign_attributes(date: @date - 1, prodhaver: 0, horas_haver: 0, sacos_rotos_haver: 4)
    idle.save!
    result = dashboard
    assert_equal 84, result.totals[:total_haver]
    assert_equal 8000, result.totals[:good_bags]
    assert_in_delta 98.95, result.totals[:quality]
    assert_in_delta 100 * 4.0 / 6, result.totals[:availability]
    assert_equal 1, result.totals[:reports]
    day = result.days.find { |row| row[:date] == idle.date }
    assert_equal 4, day[:total_haver]
    assert_nil day[:quality]
    assert_nil day[:availability]
  end

  test "shows reported counts with partial coverage while leaving period quality unknown" do
    copy = @report.dup
    copy.assign_attributes(date: @date - 1, sacos_rotos_haver: nil, sacos_no_reconocidos_haver: 52, sacos_descartados_haver: nil)
    copy.save!
    summary = dashboard.totals
    assert_equal 16000, summary[:good_bags]
    assert_equal 80, summary[:broken_bags]
    assert_equal 52, summary[:unrecognized_bags]
    assert_equal 80, summary[:total_haver]
    assert_equal 1, summary[:missing_quality]
    assert_nil summary[:quality]
    assert_nil summary[:broken]
    assert_nil summary[:oee]
  end

  test "subtracts maintenance and failures for availability and OEE" do
    summary = dashboard.totals
    assert_in_delta 200, summary[:tons]
    assert_in_delta 50, summary[:rate]
    assert_in_delta 100, summary[:performance]
    assert_in_delta 100 * 4.0 / 6, summary[:availability]
    assert_in_delta 80, summary[:reliability]
    assert_in_delta 1, summary[:broken]
    assert_in_delta 99, summary[:quality]
    assert_in_delta 66, summary[:oee]
    assert_equal [ @date ], dashboard.days.map { |day| day[:date] }
  end

  test "uses confirmed ideal by default and preserves unknown broken bags" do
    assert_in_delta 66, dashboard(ideal: nil).totals[:oee]
    assert_in_delta 100, dashboard(ideal: nil).totals[:performance]
    @report.update!(sacos_rotos_haver: nil)
    assert_nil dashboard.totals[:quality]
    assert_nil dashboard.totals[:broken]
    assert_nil dashboard.totals[:oee]
  end

  test "uses scheduled shift hours for availability and supervisor hours for reliability" do
    TptEvent.where(impact: "Parada planificada").delete_all
    TptEvent.find_by!(impact: "Correr").update!(duration_seconds: 3600)
    summary = dashboard.totals
    assert_in_delta 6, summary[:available_hours]
    assert_in_delta 100 * 5.0 / 6, summary[:availability]
    assert_in_delta 80, summary[:reliability]
    @report.update!(horas_haver: 3)
    assert_in_delta 75, dashboard.totals[:reliability]
    assert_in_delta 100 * 5.0 / 6, dashboard.totals[:availability]
  end

  test "excludes shifts without Haver production from table charts and totals" do
    idle = @report.dup
    idle.assign_attributes(date: @date - 1, prodhaver: 0, horas_haver: 2, sacos_rotos_haver: nil)
    idle.save!
    unknown = idle.dup
    unknown.assign_attributes(date: @date - 2, source_fingerprint: "missing-production", source_data: { "present_fields" => [] })
    unknown.save!
    result = dashboard
    assert_equal 1, result.shifts.size
    assert_equal @date, result.shifts.sole[:date]
    assert_equal [ @date ], result.days.map { |day| day[:date] }
    assert_equal 1, result.totals[:reports]
    assert_in_delta 50, result.totals[:rate]
    assert_in_delta 1, result.totals[:broken]
    assert_in_delta 66, result.totals[:oee]
  end

  test "keeps separate shift values and comments while aggregating chart days" do
    @report.update!(date: @date - 1, comentarios_haver: "Turno mañana")
    afternoon = @report.dup
    afternoon.assign_attributes(turno: "TT", prodhaver: 2000, horas_haver: 1, comentarios_haver: "Turno tarde")
    afternoon.save!
    result = dashboard
    assert_equal 2, result.shifts.size
    morning = result.shifts.find { |row| row[:shift] == "TM" }
    evening = result.shifts.find { |row| row[:shift] == "TT" }
    assert_equal @date - 1, morning[:date]
    assert_in_delta 200, morning[:tons]
    assert_in_delta 50, evening[:tons]
    assert_equal "Turno mañana", morning[:comment]
    assert_equal "Turno tarde", evening[:comment]
    assert_in_delta 250, result.days.find { |day| day[:date] == @date - 1 }[:tons]
    assert_in_delta 250, result.totals[:tons]
  end

  test "period ratios use totals instead of daily averages" do
    @report.update!(sacos_rotos_haver: 0)
    copy = @report.dup
    copy.assign_attributes(date: @date - 1, prodhaver: 2000, sacos_rotos_haver: 200, horas_haver: 1)
    copy.save!
    assert_in_delta 2, dashboard.totals[:broken]
    assert_in_delta 50, dashboard.totals[:rate]
    assert_in_delta (13 - 1 - 1.15) / 13 * 100, dashboard.totals[:availability]
  end

  test "rejects invalid filters and negative or fractional bag counts" do
    assert_raises(HaverDashboard::InvalidFilter) { dashboard(ideal: "0") }
    @report.sacos_rotos_haver = -1
    assert_not @report.valid?
    @report.sacos_rotos_haver = "1.5"
    assert_not @report.valid?
  end

  test "estimates missing Vorne failures from declared operation and weights period totals" do
    copy = @report.dup
    copy.assign_attributes(date: @date - 1, horas_haver: 2)
    copy.save!
    result = dashboard
    estimated = result.shifts.find { |row| row[:date] == copy.date }
    assert_in_delta 100 / 1.15, estimated[:reliability]
    assert_in_delta 0.3, estimated[:estimated_failure_hours]
    assert_equal 1, estimated[:estimated_reliability_count]
    assert_in_delta 6.0 / 7.3 * 100, result.totals[:reliability]
    assert_equal 1, result.totals[:estimated_reliability_count]
    assert_in_delta (13 - 1 - 1.3) / 13 * 100, result.totals[:availability]
    assert result.totals[:oee].positive?
  end

  test "keeps recorded zero failures and replaces estimates when Vorne arrives" do
    TptEvent.delete_all
    assert_equal 1, dashboard.totals[:estimated_reliability_count]
    imported = TptImport.first
    imported.tpt_events.create!(started_at: Time.utc(2026, 11, 14, 6), duration_seconds: 4 * 3600,
      impact: "Correr", reason: "Running Normally", production_state: "Estado", source_row: 1, source_fingerprint: SecureRandom.hex)
    assert_in_delta 100, dashboard.totals[:reliability]
    assert_equal 0, dashboard.totals[:estimated_reliability_count]
    assert_equal 0, dashboard.totals[:estimated_failure_hours]
  end

  test "cannot estimate without valid declared operation" do
    TptEvent.delete_all
    @report.update!(horas_haver: 0)
    assert_nil dashboard.totals[:reliability]
    assert_nil dashboard.totals[:availability]
    assert_equal 0, dashboard.totals[:estimated_reliability_count]
  end

  test "extra shifts use six hours and provisional downtime until Vorne is available" do
    @report.update!(turno: "TN", horas_haver: 1.93)
    summary = dashboard.totals
    assert_in_delta 6, summary[:available_hours]
    assert_in_delta (6 - 1.93 * 0.15) / 6 * 100, summary[:availability]
    assert_in_delta 100 / 1.15, summary[:reliability]
    imported = TptImport.first
    imported.tpt_events.create!(started_at: Time.utc(2026, 11, 14, 21), duration_seconds: 3600,
      impact: "Parada planificada", reason: "Intervención o Revisión", production_state: "Estado", source_row: 99, source_fingerprint: SecureRandom.hex)
    assert_in_delta 100 * 5.0 / 6, dashboard.totals[:availability]
    assert_equal 0, dashboard.totals[:estimated_reliability_count]
  end

  test "reuses envasadora Pareto and excludes events from nonproducing shifts" do
    expected = EnvasadoraDashboard.new({ period: "7" }, default_source: "haver").call.pareto
    assert_equal expected, dashboard.dashboard.pareto
    idle = @report.dup
    idle.assign_attributes(date: @date - 1, prodhaver: 0)
    idle.save!
    TptImport.first.tpt_events.create!(started_at: Time.utc(2026, 11, 13, 6), duration_seconds: 3600,
      impact: "Parada no planificada", reason: "Turno sin producción", production_state: "Estado", source_row: 99, source_fingerprint: SecureRandom.hex)
    result = dashboard.dashboard.pareto
    assert_equal expected, result
    assert_in_delta 100, result.last[:cumulative]
  end
end
