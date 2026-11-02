require "test_helper"

class EnvasadoraReportTest < ActiveSupport::TestCase
  def build_report(**attributes)
    measurements = EnvasadoraReport::SILOS.values.flat_map { |s| s[:readings] }.index_with { 10 }
    EnvasadoraReport.new(measurements.merge(date: Date.current, turno: "TM", author_email: "usuario@msindustrial.cl").merge(attributes))
  end

  test "uses full production recipients and includes Helmut only for morning creation times in Santiago" do
    assert_equal 46, EnvasadoraReport::RECIPIENTS.size
    assert_equal 46, EnvasadoraReport::RECIPIENTS.map(&:downcase).uniq.size
    assert_includes EnvasadoraReport::RECIPIENTS, "supervisor.envasadora@msindustrial.cl"
    assert_includes EnvasadoraReport::RECIPIENTS, "miguel.basulto@meloncementos.cl"
    zone = ActiveSupport::TimeZone["America/Santiago"]
    { "04:59:59" => false, "05:00:00" => true, "09:59:59" => true, "10:00:00" => false }.each do |time, includes_helmut|
      report = build_report(created_at: zone.parse("2026-11-01 #{time}").utc)
      assert_equal includes_helmut, report.recipients.include?("helmut.brandau@meloncementos.cl"), time
      assert_equal includes_helmut ? 47 : 46, report.recipients.size
    end
    assert_equal 46, build_report.recipients.size
    assert_equal 46, EnvasadoraReport::RECIPIENTS.size
  end

  test "defaults retain original silo stock and changing cement moves only that stock" do
    report = build_report(extrsacos: 25)
    assert report.valid?, report.errors.full_messages.join(", ")
    assert_equal 4025, report.inventory["Extra"][:total]
    total = report.total_tons
    report.silo19_cement = "HPM"
    assert_equal 2025, report.inventory["Extra"][:total]
    assert_equal 2000, report.inventory["HPM"][:total]
    assert_equal total, report.total_tons
    report.save!
    assert_equal "HPM", report.reload.silo19_cement
  end

  test "multiple reassigned silos combine under one product without losing floor stock" do
    report = build_report(silo19_cement: "Especial", silo20_cement: "Especial", silo28_cement: "Especial", especialsacos: 15, bigbagespecial: 5)
    assert_equal 14200, report.inventory["Especial"][:silo]
    assert_equal 14220, report.inventory["Especial"][:total]
    assert_equal 0, report.inventory["S4200"][:silo]
  end

  test "daily comparisons use each record's cement choices" do
    morning = build_report(silo19_cement: "HPM")
    morning.save!
    afternoon = build_report(turno: "TT", silo19_cement: "Ultra")
    afternoon.save!
    daily = afternoon.daily_reports
    assert_equal 2000, daily.fetch("TM").inventory["HPM"][:total]
    assert_equal 0, daily.fetch("TT").inventory["HPM"][:total]
    assert_equal 5000, daily.fetch("TT").inventory["Ultra"][:total]
  end

  test "unit counts are whole but measurements hours and tonnages accept decimals" do
    [ { prodhaver: "10.5" }, { plastificado_extra: "1.5" }, { enjuagues_super: "1.5" } ].each do |attributes|
      assert_not build_report(**attributes).valid?, attributes.inspect
    end
    assert build_report(silo19a: "10.5", extrsacos: "1200.5", extra_granel: "12.5", horas_haver: "3.5").valid?
  end

  test "single reading silos and decimals use their own capacity" do
    report = build_report(silo27: "29.5", silo28: "19.25", silo19a: "29.5", silo19b: "29")
    assert_equal 230, report.silo_tons(27)
    assert_equal 75, report.silo_tons(28)
    assert_equal 75, report.silo_tons(19)
  end

  test "production hours reject values above the shift limit and accept decimal hours" do
    EnvasadoraReport::HOUR_FIELDS.each do |field|
      assert build_report(date: Date.new(2026, 10, 26), field => "6.5").valid?
      assert build_report(date: Date.new(2026, 10, 26), field => "8").valid?
      assert_not build_report(date: Date.new(2026, 10, 26), field => "8.01").valid?
      assert_not build_report(date: Date.new(2026, 10, 26), field => "65").valid?
      assert_not build_report(date: Date.new(2026, 10, 26), field => "-1").valid?
      assert build_report(date: Date.new(2026, 10, 31), turno: "TM", field => "6").valid?
      assert_not build_report(date: Date.new(2026, 10, 31), turno: "TM", field => "6.01").valid?
    end
  end

  test "hour limits follow each weekday shift including nine hour shifts and unprogrammed weekends" do
    expected = [ [ 8, 8, 8 ], [ 7, 9, 8 ], [ 7, 9, 8 ], [ 7, 8, 9 ], [ 7, 8, 9 ], [ 6, 0, 0 ], [ 0, 0, 0 ] ]
    expected.each_with_index do |limits, index|
      date = Date.new(2026, 10, 12) + index
      %w[TM TT TN].zip(limits).each do |shift, limit|
        record = build_report(date: date, turno: shift, horas_haver: limit, horas_vento: limit, horas_bigbag: limit)
        assert_equal limit, record.hours_limit
        assert record.valid?, record.errors.full_messages.join(", ")
        record.horas_haver = limit + 0.01
        assert_not record.valid?, "#{date} #{shift} must reject hours above #{limit}"
      end
    end
  end

  test "historical hours correction restores analytics and preserves original and audit" do
    record = build_report(date: Date.new(2026, 10, 26), turno: "TT", horas_haver: 65, source_fingerprint: "correction-test",
      source_data: { "cells" => { "Horas Haver" => "65.0" }, "invalid_fields" => [ "horas_haver" ], "present_fields" => [ "horas_haver" ], "issues" => [ "Horas Haver: valor 65.0 fuera del rango esperado; se conserva el original.", "Otro dato" ] })
    record.save!(validate: false)
    record.correct_historical_hours!("horas_haver", "6.5", reason: "Corrección solicitada por el usuario")
    record.reload
    assert_equal BigDecimal("6.5"), record.value_for_analytics("horas_haver")
    assert_equal "65.0", record.source_data["cells"]["Horas Haver"]
    assert_equal [ "Otro dato" ], record.source_data["issues"]
    assert_equal 1, record.source_data["corrections"].size
    assert_equal "65.0", record.source_data["corrections"].sole["previous"]
    record.correct_historical_hours!("horas_haver", "6.5", reason: "Reintento")
    assert_equal 1, record.reload.source_data["corrections"].size
    assert_raises(ArgumentError) { record.correct_historical_hours!("horas_haver", "65", reason: "Inválido") }
  end

  test "missing readings invalid cement negative stock and out of range values are rejected" do
    [ { silo19a: nil }, { silo28: 21 }, { silo27: -1 }, { silo19_cement: "Unknown" }, { extrsacos: -1 }, { ns30001: 15 } ].each do |attributes|
      assert_not build_report(**attributes).valid?, attributes.inspect
    end
  end

  test "daily comparisons exclude other dates future shifts and later corrections" do
    build_report(date: Date.yesterday).save!
    report = build_report(turno: "TT")
    report.save!
    build_report.save!
    build_report(turno: "TN").save!
    assert_equal [ "TT" ], report.daily_reports.keys
  end
end
