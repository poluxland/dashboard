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
    assert_select "p", "Envasadora LCA · Producción, stocks y desempeño Vorne"
    assert_select 'button[name="period"][aria-current="true"].btn-primary', text: "Últimos 30 días", count: 1
    assert_select "canvas", count: 3
    assert_select "section[aria-labelledby=production-summary-title] h3", count: 3
    assert_select "section[aria-labelledby=stock-summary-title] h3", count: EnvasadoraReport::CEMENTS.size
    assert_select "section[aria-labelledby=vorne-summary-title]", text: /Vorne.*MTBF.*MTTR/m
    assert_select "input[type=file]", count: 0
    assert_select "a[href=?]", envasadora_reports_path
    assert_select "a[href=?]", tpt_imports_path
    assert_select ".alert-info", text: /No hay datos/
  end

  test "highlights the selected quick period and clears it for custom dates" do
    sign_in_with_google
    dates = { from: "2026-10-01", to: "2026-10-15" }
    EnvasadoraDashboard::PERIODS.each_key do |period|
      get envasadora_dashboard_path, params: dates.merge(period: period)
      assert_response :success
      assert_select 'button[name="period"][aria-current="true"].btn-primary', count: 1 do |buttons|
        assert_equal period, buttons.first["value"]
      end
    end
    get envasadora_dashboard_path, params: dates
    assert_response :success
    assert_select 'button[name="period"].btn-primary', count: 0
  end

  test "filters and joins production Haver with TPT while escaping reason labels" do
    sign_in_with_google
    measurements = EnvasadoraReport::SILOS.values.flat_map { |silo| silo[:readings] }.index_with { 10 }
    report = EnvasadoraReport.create!(measurements.merge(
      date: Date.new(2026, 10, 15), turno: "TN", author_email: "test@msindustrial.cl",
      prodhaver: 1234, horas_haver: 4.7, comentarios_haver: "Ajuste de <sensor>",
      prodvento: 9999, horas_vento: 2, comentarios_vento: "Cambio de formato",
      prodbb: 77, horas_bigbag: 1, comentarios_bigbag: "Limpieza de tolva"
    ))
    imported = TptImport.create!(filename: "test.xlsx", author_email: report.author_email)
    imported.tpt_events.create!(source_row: 11, impact: "Parada no planificada", production_state: "Abajo", reason: "<script>bad()</script>", started_at: Time.utc(2026, 10, 16, 1), duration_seconds: 60, source_fingerprint: "controller-test")
    get envasadora_dashboard_path, params: { from: "2026-10-15", to: "2026-10-15", shifts: [ "TN" ] }
    assert_response :success
    assert_select "#envasadora-shift-detail tbody tr", count: 1
    assert_select "#envasadora-shift-detail thead th", count: 10
    assert_select "#envasadora-shift-detail thead th:nth-child(7)", text: "Comentarios Haver"
    assert_select "#envasadora-shift-detail thead th:nth-child(8)", text: "Comentarios Ventomatic"
    assert_select "#envasadora-shift-detail thead th:nth-child(9)", text: "Comentarios Bigbag"
    assert_select "#envasadora-shift-detail tbody td:nth-child(4)", text: /1\.234\s+\(4,7 h \/ 9 h\)/
    assert_select "#envasadora-shift-detail tbody td:nth-child(5)", text: /9\.999\s+\(2 h \/ 9 h\)/
    assert_select "#envasadora-shift-detail tbody td:nth-child(6)", text: /77\s+\(1 h \/ 9 h\)/
    assert_select "#envasadora-shift-detail tbody td:nth-child(7)", text: "Ajuste de <sensor>"
    assert_select "#envasadora-shift-detail tbody td:nth-child(8)", text: "Cambio de formato"
    assert_select "#envasadora-shift-detail tbody td:nth-child(9)", text: "Limpieza de tolva"
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
