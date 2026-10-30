require "test_helper"

class TptImportsControllerTest < ActionDispatch::IntegrationTest
  test "requiere autenticación" do
    get tpt_imports_url
    assert_redirected_to login_url
    post tpt_imports_url
    assert_redirected_to login_url
  end

  test "muestra la carga y rechaza archivos ausentes o distintos a XLSX" do
    sign_in_with_google
    get tpt_imports_url
    assert_response :success
    assert_select "h1", "VentoHaver TPT"
    assert_select "input[type=file][name=archivo]", count: 1
    post tpt_imports_url
    assert_response :unprocessable_entity
    assert_no_difference("TptImport.count") do
      with_mantencion_xlsx([]) do |upload|
        post tpt_imports_url, params: { archivo: upload }
      end
    end
    assert_response :unprocessable_entity
  end

  test "muestra eventos y advertencias del historial" do
    sign_in_with_google
    report = TptImport.create!(filename: "informe.xlsx", author_email: "usuario@msindustrial.cl", imported_count: 1, issues: [ "Fila 11: duración negativa" ])
    report.tpt_events.create!(source_row: 11, impact: "Correr", production_state: "Corriendo", reason: "Running Normally", started_at: Time.utc(2026, 10, 15), duration_seconds: -1, source_fingerprint: "test")
    get tpt_import_url(report)
    assert_response :success
    assert_select "tr.table-warning", count: 1
    assert_select "details", text: /duración negativa/
    get tpt_imports_url
    assert_response :success
    assert_select ".alert-warning", text: /1 eventos tienen duración negativa/
  end

  test "importa un informe válido y pagina el detalle" do
    sign_in_with_google
    file = Tempfile.new([ "ventohaver", ".xlsx" ])
    package = Axlsx::Package.new
    package.workbook.add_worksheet(name: "Datos TPT") do |sheet|
      sheet.add_row TptExcelImporter::HEADERS
      101.times do |number|
        sheet.add_row [ "Correr", "Corriendo", "Running Normally", "2026-10-15 08:30:#{format('%02d', number % 60)}", 0.1, 1, 60, 60, 60, 60 ].tap { |row| row[2] = "Razón #{number}" }
      end
    end
    package.serialize(file.path)
    upload = Rack::Test::UploadedFile.new(file.path, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    assert_difference("TptEvent.count", 101) { post tpt_imports_url, params: { archivo: upload } }
    assert_redirected_to tpt_import_url(TptImport.last)
    follow_redirect!
    assert_response :success
    assert_select "tbody tr", count: 100
    assert_select "a[href*='page=2']"
    get tpt_import_url(TptImport.last, page: 2)
    assert_response :success
    assert_select "tbody tr", count: 1
  ensure
    file&.close!
  end
end
