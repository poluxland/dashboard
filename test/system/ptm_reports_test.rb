require "application_system_test_case"

class PtmReportsTest < ApplicationSystemTestCase
  test "operator adds and removes events then saves a PTM shift" do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: "ptm-test",
      info: { email: "usuario@msindustrial.cl", name: "Usuario", email_verified: true },
      extra: { id_info: { "hd" => "msindustrial.cl", "email_verified" => true } }
    )
    visit "/auth/google_oauth2/callback"
    visit new_ptm_report_path
    select "TM · Mañana", from: "Turno"
    fill_in "Producción (sacos)", with: "1000"
    within first("[data-event-row]") do
      fill_in "Equipo / fase", with: "Radimat"
      fill_in "Minutos", with: "45"
      fill_in "Falla / detención", with: "Ajuste de sensor"
    end
    click_on "Agregar detención"
    assert_selector "[data-event-row]", count: 2
    within all("[data-event-row]").last do
      fill_in "Equipo / fase", with: "Báscula"
      fill_in "Minutos", with: "5"
      click_on "Quitar detención"
    end
    click_on "Guardar turno"
    assert_text "Turno PTM guardado"
    assert_selector "[data-charts-ready=true]", wait: 20
    assert_selector "canvas", count: 6
    assert_selector "[data-ptm-dashboard-target='error']", visible: false
    assert_equal 1, PtmReport.last.ptm_events.count
    11.times do |index|
      PtmReport.last.ptm_events.create!(equipment: "Equipo #{index}", reason: "Causa #{index}", minutes: index + 1)
    end
    visit ptm_reports_path(period: "month")
    assert_selector "[data-charts-ready=true]", wait: 20
    %w[equipment causes].each do |target|
      data = page.evaluate_script("window.Chart.getChart(document.querySelector('[data-ptm-dashboard-target=\"#{target}\"]')).data")
      assert_equal 12, data.fetch("labels").size
      assert_not_includes data.fetch("labels"), "Otros"
      assert_in_delta 100, data.fetch("datasets").last.fetch("data").last, 0.001
    end
    page.save_screenshot(Rails.root.join("tmp/ptm-dashboard.png"))
  end
end
