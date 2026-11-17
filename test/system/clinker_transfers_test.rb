require "application_system_test_case"

class ClinkerTransfersTest < ApplicationSystemTestCase
  test "operator registers tons and sees daily weekly and monthly charts" do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: "clinker-test",
      info: { email: "usuario@msindustrial.cl", name: "Usuario", email_verified: true },
      extra: { id_info: { "hd" => "msindustrial.cl", "email_verified" => true } }
    )
    visit "/auth/google_oauth2/callback"
    visit new_clinker_transfer_path
    fill_in "Toneladas trasladadas", with: "1291"
    fill_in "Observaciones (opcional)", with: "Traslado PTM"
    click_on "Guardar traslado"
    assert_text "Traslado de clínker PTM guardado"
    assert_text "Traslado PTM"
    assert_selector "[data-charts-ready=true]", wait: 20
    assert_selector "canvas", count: 3
    assert_equal 1291, ClinkerTransfer.last.tons
    page.save_screenshot(Rails.root.join("tmp/clinker-dashboard.png"))
  end
end
