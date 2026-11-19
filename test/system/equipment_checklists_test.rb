require "application_system_test_case"

class MobileEquipmentChecklistsTest < ApplicationSystemTestCase
  test "operator submits a checklist from the login page on a phone" do
    asset = MobileAsset.create!(code: "HQ01", plant: "LCA")
    MobileAsset.create!(code: "OL02", plant: "PTM")

    page.current_window.resize_to(390, 844)
    visit login_path
    click_on "Checklist Operador"
    fill_in "Buscar por código", with: "hq01"
    assert_no_text "OL02"
    find("label", text: "HQ01", exact_text: true).click

    fill_in "Operador", with: "Operador de prueba"
    fill_in "Horómetro", with: "125"
    find("label", text: "La Calera", exact_text: true).click
    all(".equipment-choice", text: "Sí", exact_text: true, count: 16).each(&:click)
    click_on "Guardar checklist"

    assert_text "Checklist registrado."
    assert_current_path new_equipment_checklist_path
    assert_equal 125, asset.equipment_checklists.sole.hour_meter
  end
end
