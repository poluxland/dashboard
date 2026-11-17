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
    assert_select "canvas", count: 3
    assert_select "input[name=ideal][value='50.0']"
    assert_select "tbody tr", count: 7
    get haver_dashboard_path, params: { ideal: "50", period: "30" }
    assert_response :success
    assert_select 'button[name="period"][value="30"][aria-current="true"]'
    assert_select "tbody tr", count: 30
    get haver_dashboard_path, params: { ideal: "-5" }
    assert_response :unprocessable_entity
  end
end
