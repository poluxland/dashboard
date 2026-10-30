require "test_helper"

class TptExcelImporterTest < ActiveSupport::TestCase
  def with_report(rows, header_row: 7, headers: TptExcelImporter::HEADERS)
    file = Tempfile.new([ "tpt", ".xlsx" ])
    package = Axlsx::Package.new
    package.workbook.add_worksheet(name: "Datos TPT") do |sheet|
      style = package.workbook.styles.add_style(format_code: "yyyy-mm-dd hh:mm:ss.000")
      (header_row - 1).times { sheet.add_row [ "#VentoHaver" ] }
      sheet.add_row headers
      rows.each { |row| sheet.add_row row, style: [ nil, nil, nil, style ] }
    end
    package.serialize(file.path)
    yield ActionDispatch::Http::UploadedFile.new(filename: "VentoHaver.xlsx", tempfile: file)
  ensure
    file&.close!
  end

  def event(time: Time.utc(2026, 10, 15, 8, 30), duration: 60)
    [ "Correr", "Corriendo", "Running Normally", time, 0.1, 1, duration, duration, duration, duration ]
  end

  def import(upload)
    TptExcelImporter.new(upload, author_email: "usuario@msindustrial.cl").call
  end

  test "detecta encabezados y omite subtotales intercalados sin duplicar los eventos" do
    summary = [ "Correr", "Corriendo", nil, nil, 0.2, 2, 120 ]
    with_report([ summary, event, summary, event(time: Time.utc(2026, 10, 16)) ]) do |upload|
      report = import(upload)
      assert_equal 2, report.imported_count
      assert_equal 2, report.summary_count
      assert_empty report.issues
      assert_equal 9, report.tpt_events.order(:source_row).first.source_row
      again = import(upload)
      assert_equal 0, again.imported_count
      assert_equal 2, again.duplicate_count
    end
  end

  test "períodos superpuestos agregan solo eventos nuevos y notifican correcciones" do
    with_report([ event ]) { |upload| import(upload) }
    with_report([ event(duration: 80), event(time: Time.utc(2026, 10, 17)) ], header_row: 1) do |upload|
      report = import(upload)
      assert_equal 1, report.imported_count
      assert_match "otra duración", report.issues.join
      assert_equal 60, TptEvent.find_by!(started_at: Time.utc(2026, 10, 15, 8, 30)).duration_seconds
    end
  end

  test "conserva fracciones de segundo y duraciones negativas sin sumarlas" do
    with_report([ event(time: Time.utc(2026, 10, 15, 8, 30, 0.125), duration: -0.001039) ]) do |upload|
      report = import(upload)
      record = report.tpt_events.sole
      assert_in_delta 125000, record.started_at.usec, 1
      assert_equal BigDecimal("-0.001039"), record.duration_seconds
      assert_equal 0, report.tpt_events.nonnegative.count
      assert_match "negativa", report.issues.join
    end
  end

  test "rechaza un archivo ajeno sin crear historial" do
    with_report([ event ], headers: [ "Otro informe" ]) do |upload|
      assert_no_difference("TptImport.count") do
        assert_raises(TptExcelImporter::InvalidSpreadsheet) { import(upload) }
      end
    end
  end

  test "informa filas inválidas y acepta las válidas" do
    malformed = event
    malformed[3] = "fecha inválida"
    with_report([ malformed, event, event ]) do |upload|
      report = import(upload)
      assert_equal 1, report.imported_count
      assert_equal 1, report.duplicate_count
      assert_match "Fila 8", report.issues.join
    end
  end
end
