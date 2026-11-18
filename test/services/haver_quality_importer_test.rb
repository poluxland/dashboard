require "test_helper"

class HaverQualityImporterTest < ActiveSupport::TestCase
  setup do
    @date = Date.new(2026, 10, 1)
    measurements = EnvasadoraReport::SILOS.values.flat_map { |silo| silo[:readings] }.index_with(10)
    attributes = measurements.merge(date: @date, author_email: "test@msindustrial.cl", horas_haver: 2)
    @morning = EnvasadoraReport.create!(attributes.merge(turno: "TM", prodhaver: 7000))
    @afternoon = EnvasadoraReport.create!(attributes.merge(turno: "TT", prodhaver: 3000, source_fingerprint: "quality-history",
      source_data: { "present_fields" => %w[prodhaver horas_haver], "cells" => { "original" => "preserved" } }))
    @payload = {
      "filename" => "Reporte GM.xlsx", "sheet" => "Hoja1", "sha256" => "a" * 64, "missing_policy" => "pending",
      "rows" => [ { "date" => @date.iso8601, "column" => "B", "sacos_rotos_haver" => 13,
        "sacos_descartados_haver" => 113, "sacos_no_reconocidos_haver" => 52, "good_bags_reference" => 9999 } ]
    }
  end

  test "distributes exact daily integer counts and preserves historical production and provenance" do
    result = HaverQualityImporter.new(@payload).call
    assert_equal 2, result[:updated]
    [ @morning, @afternoon ].each(&:reload)
    assert_equal [ 9, 4 ], [ @morning.sacos_rotos_haver, @afternoon.sacos_rotos_haver ]
    assert_equal [ 79, 34 ], [ @morning.sacos_descartados_haver, @afternoon.sacos_descartados_haver ]
    assert_equal [ 36, 16 ], [ @morning.sacos_no_reconocidos_haver, @afternoon.sacos_no_reconocidos_haver ]
    assert_equal 3000, @afternoon.prodhaver
    assert_equal 4, @afternoon.value_for_analytics("sacos_rotos_haver")
    assert_equal({ "original" => "preserved" }, @afternoon.source_data["cells"])
    assert_equal 13, @afternoon.source_data.dig("haver_quality_import", "source", "sacos_rotos_haver")
    again = HaverQualityImporter.new(@payload).call
    assert_equal 0, again[:updated]
    assert_equal 2, again[:unchanged]
  end

  test "validates without writing and preserves blanks unless zero is explicitly selected" do
    @payload["rows"].first["sacos_rotos_haver"] = nil
    HaverQualityImporter.new(@payload).call(dry_run: true)
    assert_empty @afternoon.reload.source_data.fetch("present_fields") & EnvasadoraReport::HAVER_QUALITY_FIELDS.keys
    HaverQualityImporter.new(@payload).call
    assert_nil @morning.reload.sacos_rotos_haver
    assert_nil @afternoon.reload.value_for_analytics("sacos_rotos_haver")
  end

  test "zero policy records zero while retaining the original missing source cell" do
    @payload["missing_policy"] = "zero"
    @payload["rows"].first["sacos_rotos_haver"] = nil
    HaverQualityImporter.new(@payload).call
    assert_equal 0, @afternoon.reload.value_for_analytics("sacos_rotos_haver")
    assert_nil @afternoon.source_data.dig("haver_quality_import", "source", "sacos_rotos_haver")
  end

  test "uses latest shift snapshots and preserves losses on days without production" do
    old = @morning.dup
    old.assign_attributes(created_at: 1.day.ago, updated_at: 1.day.ago, prodhaver: 999999)
    old.save!
    [ @morning, @afternoon ].each { |report| report.update!(prodhaver: 0) }
    result = HaverQualityImporter.new(@payload).call
    assert_equal [ @date ], result[:without_production]
    assert_equal 0, @morning.reload.sacos_rotos_haver
    assert_equal 13, @afternoon.reload.sacos_rotos_haver
    assert_nil old.reload.sacos_rotos_haver
  end

  test "rolls back the whole import if a later date is missing or existing counts conflict" do
    @payload["rows"] << @payload["rows"].first.merge("date" => (@date + 1).iso8601)
    assert_raises(HaverQualityImporter::InvalidImport) { HaverQualityImporter.new(@payload).call }
    assert_nil @morning.reload.sacos_rotos_haver
    @payload["rows"].pop
    @afternoon.update_columns(sacos_rotos_haver: 999)
    assert_raises(HaverQualityImporter::InvalidImport) { HaverQualityImporter.new(@payload).call }
    assert_nil @morning.reload.sacos_rotos_haver
    assert_equal 999, @afternoon.reload.sacos_rotos_haver
  end

  test "rejects invalid source counts and duplicate dates before updating" do
    @payload["rows"].first["sacos_rotos_haver"] = -1
    assert_raises(HaverQualityImporter::InvalidImport) { HaverQualityImporter.new(@payload).call }
    @payload["rows"].first["sacos_rotos_haver"] = 1.5
    assert_raises(HaverQualityImporter::InvalidImport) { HaverQualityImporter.new(@payload).call }
    @payload["rows"].first["sacos_rotos_haver"] = 13
    @payload["rows"] *= 2
    assert_raises(HaverQualityImporter::InvalidImport) { HaverQualityImporter.new(@payload).call }
    assert_nil @morning.reload.sacos_rotos_haver
  end
end
