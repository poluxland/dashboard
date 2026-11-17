require "test_helper"

class HaverDashboardTest < ActiveSupport::TestCase
  setup do
    @date = Date.new(2026, 11, 14)
    measurements = EnvasadoraReport::SILOS.values.flat_map { |silo| silo[:readings] }.index_with(10)
    @report = EnvasadoraReport.create!(measurements.merge(date: @date, turno: "TM", author_email: "test@msindustrial.cl", prodhaver: 8000, horas_haver: 4, sacos_rotos_haver: 80))
    imported = TptImport.create!(filename: "haver.xlsx", author_email: "test@msindustrial.cl")
    [[6, 4, "Correr", "Running Normally"], [10, 1, "Parada planificada", "Intervención o Revisión"], [11, 1, "Parada no planificada", "Cintas Haver"]].each do |hour, duration, impact, reason|
      imported.tpt_events.create!(started_at: Time.utc(2026, 11, 14, hour), duration_seconds: duration * 3600, impact: impact, reason: reason, production_state: "Estado", source_row: hour, source_fingerprint: SecureRandom.hex)
    end
  end

  def dashboard(ideal: "50")
    HaverDashboard.new(week: @date.iso8601, month: "2026-11", ideal: ideal)
  end

  test "calculates both availability formulas and OEE using added failures" do
    summary = dashboard.monthly
    assert_in_delta 200, summary[:tons]
    assert_in_delta 50, summary[:rate]
    assert_in_delta 100, summary[:performance]
    assert_in_delta 100, summary[:availability_plus]
    assert_in_delta 100 * 4.0 / 6, summary[:availability_minus]
    assert_in_delta 80, summary[:reliability]
    assert_in_delta 1, summary[:broken]
    assert_in_delta 99, summary[:quality]
    assert_in_delta 99, summary[:oee]
    assert_equal 7, dashboard.days.size
    assert_nil dashboard.days.first[:tons]
  end

  test "uses confirmed ideal by default and preserves unknown broken bags" do
    assert_in_delta 99, dashboard(ideal: nil).monthly[:oee]
    assert_in_delta 100, dashboard(ideal: nil).monthly[:performance]
    @report.update!(sacos_rotos_haver: nil)
    assert_nil dashboard.monthly[:quality]
    assert_nil dashboard.monthly[:broken]
    assert_nil dashboard.monthly[:oee]
  end

  test "monthly ratios use totals instead of daily averages" do
    @report.update!(sacos_rotos_haver: 0)
    copy = @report.dup
    copy.assign_attributes(date: @date - 1, prodhaver: 2000, sacos_rotos_haver: 200, horas_haver: 1)
    copy.save!
    assert_in_delta 2, dashboard.monthly[:broken]
    assert_in_delta 50, dashboard.monthly[:rate]
    assert_nil dashboard.monthly[:availability_plus]
  end

  test "rejects invalid filters and negative or fractional bag counts" do
    assert_raises(HaverDashboard::InvalidFilter) { dashboard(ideal: "0") }
    assert_raises(HaverDashboard::InvalidFilter) { HaverDashboard.new(week: "bad") }
    @report.sacos_rotos_haver = -1
    assert_not @report.valid?
    @report.sacos_rotos_haver = "1.5"
    assert_not @report.valid?
  end
end
