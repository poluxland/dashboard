require "application_system_test_case"

class MobileEquipmentChecklistsTest < ApplicationSystemTestCase
  test "operator searches for an equipment code and fills in the checklist on a phone" do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: "mobile-equipment-test",
      info: { email: "usuario@msindustrial.cl", name: "Usuario", email_verified: true },
      extra: { id_info: { "hd" => "msindustrial.cl", "email_verified" => true } }
    )
    asset = MobileAsset.create!(code: "HQ01", plant: "LCA")
    MobileAsset.create!(code: "OL02", plant: "PTM")

    page.current_window.resize_to(390, 844)
    visit "/auth/google_oauth2/callback"
    visit new_equipment_checklist_path
    fill_in "Buscar por código, marca o modelo", with: "hq01"
    assert_no_text "OL02"
    find("label", text: "HQ01", exact_text: true).click

    fill_in "Operador", with: "Operador de prueba"
    fill_in "Horómetro", with: "125"
    find("label", text: "La Calera", exact_text: true).click
    all(".equipment-choice", text: "Sí", exact_text: true, count: 16).each(&:click)
    click_on "Guardar checklist"

    assert_text "Checklist de HQ01"
    assert_text "Sin fallas"
    assert_equal 125, asset.equipment_checklists.sole.hour_meter
  ensure
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end
end
