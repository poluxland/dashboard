require "test_helper"

class HaverDashboardControllerTest < ActionDispatch::IntegrationTest
  test "requires login" do
    get haver_dashboard_path
    assert_redirected_to login_path
  end

  test "renders period charts totals and confirmed ideal" do
    sign_in_with_google
    get haver_dashboard_path
    assert_response :success
    assert_select "h1", "Informe Haver · LCA"
    assert_select "canvas", count: 5
    assert_select "canvas[data-haver-dashboard-target]" do |canvases|
      assert_equal %w[production indicators pareto broken bagCounts], canvases.map { |canvas| canvas["data-haver-dashboard-target"] }
    end
    assert_select "#haver-pareto > .col-lg-3 h3", "Resumen del período"
    assert_select "#haver-pareto dt", "Tiempo total de detenciones"
    assert_select "#haver-pareto dt", "Eventos de detención"
    assert_select "#haver-pareto dt", "Principal causa por tiempo"
    assert_select 'canvas[data-haver-dashboard-target="bagCounts"]', count: 1
    assert_select "#haver-pareto-detail"
    assert_select 'button[name="period"][value="previous"][aria-current="true"]'
    assert_select "input[name=ideal][value='50.0']"
    assert_select "td[colspan='16']", text: "Sin producción ni pérdidas Haver informadas en este período."
    assert_select "#haver-bag-quality th", text: "Buenos"
    assert_select "#haver-bag-quality th", text: "No reconocidos"
    assert_select "#haver-bag-quality th", text: "Descartados"
    assert_select "#haver-bag-quality th", text: "Total Haver"
    get haver_dashboard_path, params: { ideal: "50", period: "30" }
    assert_response :success
    assert_select 'button[name="period"][value="30"][aria-current="true"]'
    assert_select "th", text: "Turno"
    get haver_dashboard_path, params: { ideal: "-5" }
    assert_response :unprocessable_entity
  end
end
