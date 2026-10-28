require "test_helper"

class EnvasadoraReportTest < ActiveSupport::TestCase
  def build_report(**attributes)
    measurements = EnvasadoraReport::SILOS.values.flat_map { |s| s[:readings] }.index_with { 10 }
    EnvasadoraReport.new(measurements.merge(date: Date.current, turno: "TM", author_email: "usuario@msindustrial.cl").merge(attributes))
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
