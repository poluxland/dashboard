require "application_system_test_case"

class PmmTruckFiltersSystemTest < ApplicationSystemTestCase
  test "category selections refresh the report without reloading the page" do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: "arrivals-filters-test",
      info: { email: "usuario@msindustrial.cl", name: "Usuario", email_verified: true },
      extra: { id_info: { "hd" => "msindustrial.cl", "email_verified" => true } }
    )
    date = PmmTruck::CHILE.today
    [ "Arena", "Caliza" ].each_with_index do |name, index|
      material = PmmMaterial.create!(nombre: name)
      PmmTruck.create!(pmm_material: material, fecha: date, tipo: "Plano", patente: "FILTRO#{index}",
        llegada: "08:00", salida: "09:00", wait: 60, finished: true, motive: "Observación")
    end

    visit "/auth/google_oauth2/callback"
    visit arrivals_pmm_trucks_path
    assert_no_button "Aplicar filtros"
    assert_selector "table[aria-label='Comentarios de camiones'] tbody tr", count: 2
    page.execute_script("window.arrivalFilterPage = true")

    find("label.btn-outline-primary", text: "Arena", exact_text: true).click
    assert_selector "table[aria-label='Comentarios de camiones'] tbody tr", count: 1, text: /FILTRO0/
    assert page.evaluate_script("window.arrivalFilterPage === true")

    find("label.btn-outline-primary", text: "Caliza", exact_text: true).click
    assert_selector "table[aria-label='Comentarios de camiones'] tbody tr", count: 2
    assert_selector "input.btn-check[name='material_ids[]']:checked", visible: :all, count: 2
  end
end
