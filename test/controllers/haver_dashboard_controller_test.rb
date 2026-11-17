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
    assert_select "canvas", count: 4
    assert_select "#haver-pareto-detail"
    assert_select 'button[name="period"][value="previous"][aria-current="true"]'
    assert_select "input[name=ideal][value='50.0']"
    assert_select "td[colspan='11']", text: "Sin turnos con producción Haver en este período."
    get haver_dashboard_path, params: { ideal: "50", period: "30" }
    assert_response :success
    assert_select 'button[name="period"][value="30"][aria-current="true"]'
    assert_select "th", text: "Turno"
    get haver_dashboard_path, params: { ideal: "-5" }
    assert_response :unprocessable_entity
  end
end
