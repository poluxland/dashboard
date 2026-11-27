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
    assert_select "a[href=?]", apr_history_entries_path, text: "Histórico"
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

  test "shows reviewed activity fields alongside the original text and finds them in search" do
    with_workbook(@rows) { |path| AprHistoryImporter.new(path).call(apply: true) }
    record = AprHistoryEntry.find_by!(source_row: 3)
    record.update!(activity_details: { "2" => { "type" => "Entrega de EPP", "sector" => "Granel", "result" => "Entregado al personal" } })
    sign_in_with_google(email: "jose.jerez@msindustrial.cl")

    get apr_history_entries_path(q: "Granel")
    assert_select "tbody tr", count: 1
    assert_select "tbody a[href=?]", apr_history_entry_path(record, anchor: "actividad-2")
    assert_select "tbody td.apr-history-activity", text: "Entregar EPP"
    get apr_history_entry_path(record)
    assert_select "li", text: /Validar AST/, count: 1
    assert_select "li", text: /Entregar EPP.*Entrega de EPP.*Granel.*Entregado al personal/m, count: 1
    assert_select "dt", text: "Duración", count: 0
    assert_equal [ "Validar AST", "Entregar EPP", "Revisar señalización" ], record.reload.activities
  end

  test "lists every activity in its own row and expands long activity text and observations" do
    with_workbook(@rows) { |path| AprHistoryImporter.new(path).call(apply: true) }
    record = AprHistoryEntry.find_by!(source_row: 3)
    long_activity = "Revisar señalización " + ("de la zona de trabajo " * 8) + "en acceso norte."
    long_observations = ("Observación de la jornada. " * 6) + "Fin del comentario."
    details = {
      "2" => { "type" => "Entrega de EPP", "sector" => "Granel" },
      "3" => { "equipment" => "Silo 2000", "platform" => "PREVSIS", "result" => "Señalización revisada" }
    }
    record.update!(activities: [ "Validar AST", "Entregar EPP", long_activity ], observations: long_observations, activity_details: details)
    sign_in_with_google(email: "jose.jerez@msindustrial.cl")

    get apr_history_entries_path(from: "2025-08-04", to: "2025-08-04")
    assert_response :success
    assert_select "tbody tr", count: 3
    assert_select "th", text: "Resultado documentado"
    assert_select "td.apr-history-activity > span", text: "Validar AST"
    assert_select "td.apr-history-activity details:not([open]) summary", text: /Ver detalle/
    assert_select "td.apr-history-activity details p", text: long_activity
    assert_select "td.apr-history-observations details p", text: long_observations, count: 3
    assert_select "tbody tr:nth-child(2) td", text: "Granel"
    assert_select "tbody tr:nth-child(3) td", text: "PREVSIS"
    assert_select "tbody tr:nth-child(3) a[href=?]", apr_history_entry_path(record, anchor: "actividad-3")
    get apr_history_entry_path(record)
    assert_select "#actividad-3", text: /en acceso norte/
  end

  test "paginates individual activities within a single date" do
    with_workbook(@rows) { |path| AprHistoryImporter.new(path).call(apply: true) }
    record = AprHistoryEntry.find_by!(source_row: 3)
    record.update!(activities: (1..32).map { |position| "Actividad #{position}" })
    sign_in_with_google(email: "jose.jerez@msindustrial.cl")

    get apr_history_entries_path(from: "2025-08-04", to: "2025-08-04")
    assert_select "p", text: "32 filas"
    assert_select "tbody tr", count: 30
    assert_select "td.apr-history-activity", text: "Actividad 30"
    get apr_history_entries_path(from: "2025-08-04", to: "2025-08-04", page: 2)
    assert_select "tbody tr", count: 2
    assert_select "tbody tr:first-child td.apr-history-activity", text: "Actividad 31"
    assert_select "tbody tr:last-child td.apr-history-activity", text: "Actividad 32"
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
