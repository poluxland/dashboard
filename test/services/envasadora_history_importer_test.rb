require "test_helper"

class EnvasadoraHistoryImporterTest < ActiveSupport::TestCase
  def source_row(row: 3, shift: "TM", production: "100", hours: "2", overrides: {})
    cells = { "A" => "2026-10-15", "B" => shift, "X" => production, "Y" => hours }
    %w[C D E F G H I J K L].each { |column| cells[column] = "10" }
    { "row" => row, "cells" => cells.merge(overrides).compact }
  end

  def payload(rows)
    { "filename" => "history.xlsx", "sheet" => "Sheet1", "sha256" => "a" * 64, "selection" => "first",
      "headers" => EnvasadoraHistoryImporter::COLUMNS.to_h { |column| [ column["column"], column["header"] ] }, "rows" => rows }
  end

  def normal_report
    fields = EnvasadoraReport::SILOS.values.flat_map { |silo| silo[:readings] }.index_with { 10 }
    EnvasadoraReport.create!(fields.merge(date: Date.new(2026, 10, 28), turno: "TM", author_email: "test@msindustrial.cl", prodhaver: 2, horas_haver: 2))
  end

  test "imports only known shifts and first occurrence and is idempotent without sending email" do
    data = payload([ source_row, source_row(row: 4, production: "999"), source_row(row: 5, shift: "TT"), source_row(row: 6, shift: "") ])
    assert_no_difference("ActionMailer::Base.deliveries.size") do
      result = EnvasadoraHistoryImporter.new(data).call
      assert_equal 2, result[:created]
      assert_equal 1, result[:older_duplicates]
      assert_equal 1, result[:skipped_without_shift]
    end
    report = EnvasadoraReport.find_by!(turno: "TM")
    assert report.historical?
    assert_equal 100, report.prodhaver
    assert_equal "100", report.source_data["cells"]["Prod. Haver (unid)"]
    assert_equal 3, report.source_row
    assert_nil report.sent_at
    again = EnvasadoraHistoryImporter.new(data).call
    assert_equal 0, again[:created]
    assert_equal 2, again[:already_present]
  end

  test "preserves source anomalies and missing data without using them as analytic values" do
    data = payload([ source_row(hours: nil, overrides: { "L" => "25", "AD" => "-2", "AR" => "Ultra Metro" }), source_row(row: 4, shift: "TT", hours: "3371") ])
    EnvasadoraHistoryImporter.new(data).call
    report = EnvasadoraReport.find_by!(turno: "TM")
    assert_equal 25, report.silo28
    assert_nil report.value_for_analytics("horas_haver")
    assert_nil report.value_for_analytics("prodvento")
    assert_nil report.inventory_for_display
    assert_equal "Ultra Metro", report.source_data["cells"]["Silos 3000 tolva 1 (producto)"]
    assert report.source_data["issues"].any?
    assert_nil EnvasadoraReport.find_by!(turno: "TT").value_for_analytics("horas_haver")
  end

  test "atomically replaces only the specified unchanged sole test report" do
    test_report = normal_report
    expected = test_report.attributes.slice(*EnvasadoraHistoryImporter::TEST_RECORD_FIELDS).as_json
    importer = EnvasadoraHistoryImporter.new(payload([ source_row ]))
    result = importer.call(replace_test_record: expected)
    assert result[:test_record_removed]
    assert_not EnvasadoraReport.exists?(test_report.id)
    assert_equal 1, EnvasadoraReport.count
    assert EnvasadoraReport.sole.historical?
    again = importer.call(replace_test_record: expected)
    assert_equal 0, again[:created]
  end

  test "refuses to delete a changed test report or other real reports" do
    test_report = normal_report
    expected = test_report.attributes.slice(*EnvasadoraHistoryImporter::TEST_RECORD_FIELDS).as_json
    test_report.update!(prodhaver: 3)
    assert_no_difference("EnvasadoraReport.count") do
      assert_raises(EnvasadoraHistoryImporter::InvalidHistory) do
        EnvasadoraHistoryImporter.new(payload([ source_row ])).call(replace_test_record: expected)
      end
    end
    test_report.update!(prodhaver: 2)
    normal_report
    assert_no_difference("EnvasadoraReport.count") do
      assert_raises(EnvasadoraHistoryImporter::InvalidHistory) do
        EnvasadoraHistoryImporter.new(payload([ source_row ])).call(replace_test_record: expected)
      end
    end
  end

  test "database failure rolls back deletion and inserts" do
    test_report = normal_report
    expected = test_report.attributes.slice(*EnvasadoraHistoryImporter::TEST_RECORD_FIELDS).as_json
    # Corrupted input reusing a source row must fail the database fingerprint index.
    data = payload([ source_row, source_row(shift: "TT") ])
    assert_raises(ActiveRecord::RecordNotUnique) do
      EnvasadoraHistoryImporter.new(data).call(replace_test_record: expected)
    end
    assert_equal [ test_report.id ], EnvasadoraReport.pluck(:id)
  end
end
