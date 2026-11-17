require "test_helper"

class PtmReportsControllerTest < ActionDispatch::IntegrationTest
  test "requires login" do
    get ptm_reports_path
    assert_redirected_to login_path
  end

  test "dashboard and nested form render and save" do
    sign_in_with_google
    get ptm_reports_path
    assert_response :success
    assert_select "canvas", count: 6
    get new_ptm_report_path
    assert_response :success
    assert_select "template", count: 1
    assert_difference "PtmReport.count" do
      post ptm_reports_path, params: { ptm_report: { date: "2026-11-17", shift: "TM", production: 3000,
        ptm_events_attributes: { "0" => { equipment: "Mnatenimiento", reason: "Revisión", minutes: 30 } } } }
    end
    assert_redirected_to ptm_reports_path(period: "month")
    assert_equal "Mantenimiento", PtmReport.last.ptm_events.first.equipment
    get ptm_reports_path(period: "all")
    assert_response :success
    assert_select "td", text: "Mantenimiento", count: 0
    get edit_ptm_report_path(PtmReport.last)
    assert_response :success
  end

  test "duplicate shifts rejected and imported records protected" do
    sign_in_with_google
    report = PtmReport.create!(date: Date.current, shift: "TN", source_key: "imported", author_email: "import")
    get edit_ptm_report_path(report)
    assert_redirected_to ptm_reports_path
    assert_no_difference "PtmReport.count" do
      post ptm_reports_path, params: { ptm_report: { date: Date.current, shift: "TN", production: 0 } }
    end
    assert_response :unprocessable_entity
  end
end
