require "test_helper"
require "tempfile"

class AprHistoryTest < ActionDispatch::IntegrationTest
  setup do
    @rows = [
      [ Date.new(2025, 8, 4), "Planta", "• Validar AST\n• Entregar EPP", "Comentario de la fila" ],
      [ nil, nil, "• Revisar señalización", nil ],
      [ "9/3/2026  al 18/3/2026", "Planta", "Vacaciones", nil ],
      [ Date.new(2026, 4, 5), "Planta Calbuco", "Inspección", nil ]
    ]
  end

  test "imports dated rows and continuations with traceable source data and is idempotent" do
    with_workbook(@rows) do |path|
      importer = AprHistoryImporter.new(path)
      assert_no_difference "AprHistoryEntry.count" do
        assert_equal 4, importer.call.fetch(:source_rows)
      end
      assert_difference "AprHistoryEntry.count", 3 do
        result = importer.call(apply: true)
        assert_equal [ 3, 4, 1, 1 ], result.values_at(:inserted, :activities, :comments, :date_ranges)
        assert_equal({ "PTM" => 2, "CALBUCO" => 1 }, result.fetch(:plants))
      end
      assert_no_difference "AprHistoryEntry.count" do
        assert_equal 0, importer.call(apply: true).fetch(:inserted)
      end
    end

    record = AprHistoryEntry.find_by!(source_row: 3)
    assert_equal 4, record.source_end_row
    assert_equal [ "Validar AST", "Entregar EPP", "Revisar señalización" ], record.activities
    assert_equal "Comentario de la fila", record.observations
    range = AprHistoryEntry.find_by!(day_status: "Vacaciones")
    assert_equal [ Date.new(2026, 3, 9), Date.new(2026, 3, 18) ], [ range.date, range.end_date ]
    assert_empty range.activities
    assert_nil range.observations
  end

  test "a changed row or orphan continuation cannot overwrite the history" do
    with_workbook(@rows) { |path| AprHistoryImporter.new(path).call(apply: true) }
    changes = @rows.deep_dup
    changes.first[2] = "Texto sustituido"
    changes << [ Date.new(2026, 4, 6), "Planta", "Entrada adicional", nil ]
    assert_no_difference "AprHistoryEntry.count" do
      with_workbook(changes) do |path|
        assert_raises(AprHistoryImporter::InvalidSpreadsheet) { AprHistoryImporter.new(path).call(apply: true) }
      end
      with_workbook(@rows.rotate) do |path|
        assert_raises(AprHistoryImporter::InvalidSpreadsheet) { AprHistoryImporter.new(path).call(apply: true) }
      end
    end
    assert_equal "Validar AST", AprHistoryEntry.find_by!(source_row: 3).activities.first
  end

  test "history and comments require authorized access and date filters match overlapping periods" do
    with_workbook(@rows) { |path| AprHistoryImporter.new(path).call(apply: true) }
    record = AprHistoryEntry.find_by!(source_row: 3)
    get apr_history_entries_path
    assert_redirected_to login_path
    sign_in_with_google
    get apr_history_entry_path(record)
    assert_response :forbidden
    sign_in_with_google(email: "jose.jerez@msindustrial.cl")
    get apr_activities_path
    assert_select "a[href=?]", apr_history_entries_path, text: "Histórico Excel"
    get apr_history_entries_path(from: "2026-03-10", to: "2026-03-11")
    assert_response :success
    assert_select "tbody tr", count: 1, text: /Vacaciones/
    get apr_history_entries_path(plant: "CALBUCO")
    assert_select "tbody tr", count: 1, text: /Calbuco/
    get apr_history_entry_path(record)
    assert_response :success
    assert_select "li", text: "Revisar señalización"
    assert_select "p", text: "Comentario de la fila"
  end

  private

  def with_workbook(rows)
    workbook = Axlsx::Package.new
    workbook.workbook.add_worksheet(name: "INFORME  SEGURIDAD") do |sheet|
      sheet.add_row []
      sheet.add_row %w[Fecha Área Actividad Comentarios]
      rows.each { |row| sheet.add_row row }
    end
    Tempfile.create([ "apr-history-test", ".xlsx" ]) do |file|
      workbook.serialize(file.path)
      yield file.path
    end
  end
end
