require "application_system_test_case"

class EnvasadoraReportsTest < ApplicationSystemTestCase
  test "operator chooses cement and reviews calculated stock before sending" do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: "envasadora-test",
      info: { email: "usuario@msindustrial.cl", name: "Usuario", email_verified: true },
      extra: { id_info: { "hd" => "msindustrial.cl", "email_verified" => true } }
    )
    visit "/auth/google_oauth2/callback"
    visit new_envasadora_report_path
    select "Turno Mañana", from: "Turno"
    EnvasadoraReport::SILOS.each do |_id, silo|
      silo[:readings].each { |field| fill_in "envasadora_report_#{field}", with: "10" }
    end
    select "HPM", from: "envasadora_report_silo19_cement"
    page.save_screenshot(Rails.root.join("tmp/envasadora-form.png"))
    click_on "Guardar y revisar reporte"
    assert_text "Reporte guardado"
    assert_selector "tr", text: /HPM.*2\.000/
    assert_button "Enviar reporte por correo"
    page.scroll_to(:top)
    page.save_screenshot(Rails.root.join("tmp/envasadora-report.png"))
    click_on "Enviar reporte por correo"
    assert_text "Reporte envasadora enviado"
    assert_no_button "Enviar reporte por correo"
  end
end
