require "test_helper"

class EnvasadoraDashboardControllerTest < ActionDispatch::IntegrationTest
  test "requires corporate session" do
    get envasadora_dashboard_path
    assert_redirected_to login_path
  end

  test "renders empty dashboard and links to existing input sections" do
    sign_in_with_google
    get envasadora_dashboard_path
    assert_response :success
    assert_select "h1", "Productividad y detenciones"
    assert_select "canvas", count: 3
    assert_select "input[type=file]", count: 0
    assert_select "a[href=?]", envasadora_reports_path
    assert_select "a[href=?]", tpt_imports_path
    assert_select ".alert-info", text: /No hay datos/
  end

  test "filters and joins production Haver with TPT while escaping reason labels" do
    sign_in_with_google
    measurements = EnvasadoraReport::SILOS.values.flat_map { |silo| silo[:readings] }.index_with { 10 }
    report = EnvasadoraReport.create!(measurements.merge(date: Date.new(2026, 10, 15), turno: "TN", prodhaver: 1234, prodvento: 9999, horas_haver: 2, author_email: "test@msindustrial.cl"))
    imported = TptImport.create!(filename: "test.xlsx", author_email: report.author_email)
    imported.tpt_events.create!(source_row: 11, impact: "Parada no planificada", production_state: "Abajo", reason: "<script>bad()</script>", started_at: Time.utc(2026, 10, 16, 1), duration_seconds: 60, source_fingerprint: "controller-test")
    get envasadora_dashboard_path, params: { from: "2026-10-15", to: "2026-10-15", shifts: [ "TN" ] }
    assert_response :success
    assert_select "#envasadora-shift-detail tbody tr", count: 1
    assert_select "#envasadora-shift-detail tbody", text: /1.234/
    assert_select "#envasadora-shift-detail tbody", text: /9.999/, count: 0
    assert_select "#envasadora-pareto-detail script", count: 0
    assert_includes response.body, "&lt;script&gt;bad()&lt;/script&gt;"
    assert_select "a[href=?]", envasadora_report_path(report)
    get envasadora_dashboard_path, params: { from: "2026-10-15", to: "2026-10-15", shifts: [ "TM" ] }
    assert_response :success
    assert_select ".alert-info", text: /No hay datos/
  end

  test "invalid date does not raise server error" do
    sign_in_with_google
    get envasadora_dashboard_path, params: { from: "2026-99-01" }
    assert_response :unprocessable_entity
    assert_select ".alert-danger", text: /fechas válidas/
  end

  test "Missing Reason is opt in and the checkbox follows the submitted filter" do
    sign_in_with_google
    measurements = EnvasadoraReport::SILOS.values.flat_map { |silo| silo[:readings] }.index_with { 10 }
    EnvasadoraReport.create!(measurements.merge(date: Date.new(2026, 10, 15), turno: "TM", prodhaver: 100, horas_haver: 2, author_email: "test@msindustrial.cl"))
    imported = TptImport.create!(filename: "missing.xlsx", author_email: "test@msindustrial.cl")
    imported.tpt_events.create!(source_row: 11, impact: "Parada no planificada", production_state: "Abajo", reason: "Missing Reason", started_at: Time.utc(2026, 10, 15, 8), duration_seconds: 60, source_fingerprint: "missing-reason-filter")
    filters = { from: "2026-10-15", to: "2026-10-15" }
    get envasadora_dashboard_path, params: filters
    assert_response :success
    assert_select "input[type=checkbox][name=include_missing_reason]:not([checked])", count: 1
    assert_select "#envasadora-pareto-detail tbody", text: /Missing Reason/, count: 0
    get envasadora_dashboard_path, params: filters.merge(include_missing_reason: "1")
    assert_response :success
    assert_select "input[type=checkbox][name=include_missing_reason][checked]", count: 1
    assert_select "#envasadora-pareto-detail tbody", text: /Missing Reason/
    assert_select "label[for=include_missing_reason]", "Incluir Missing reason"
  end
end
