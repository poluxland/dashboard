require "test_helper"
require "csv"

class MaintenanceChecklistsTest < ActionDispatch::IntegrationTest
  setup do
    @asset = MobileAsset.create!(code: "HQ01", plant: "LCA")
  end

  teardown do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  test "registers and edits the full maintainer checklist" do
    sign_in_with_google
    get new_maintenance_checklist_path(asset_id: @asset.id)
    assert_response :success
    assert_select "form[autocomplete=off]"
    assert_select "form select", count: 0
    assert_select "input[name='maintenance_checklist[c19]'][type=radio]", count: 2
    assert_select "form input[type=radio][checked]", count: 0
    assert_select "input[name='maintenance_checklist[nuto_oil]'][type=number]"

    answers = MaintenanceChecklist::QUESTIONS.keys.index_with { "true" }.merge(c2: "false")
    fluids = MaintenanceChecklist::FLUIDS.keys.index_with { "12" }
    assert_difference "MaintenanceChecklist.count" do
      post maintenance_checklists_path, params: { maintenance_checklist: answers.merge(fluids).merge(
        mobile_asset_id: @asset.id, technician: "Mantenedora", operating_status: "Operativo", hour_meter: "120,5"
      ) }
    end

    record = MaintenanceChecklist.find_by!(technician: "Mantenedora")
    assert_redirected_to record
    assert_equal "120,5", record.hour_meter
    assert_equal false, record.c2
    assert_equal true, record.c19
    assert_equal 12, record.nuto_oil
    get edit_maintenance_checklist_path(record)
    assert_select "input[name='maintenance_checklist[c2]'][value=false][checked]"
    assert_select "input[name='maintenance_checklist[c19]'][value=true][checked]"
    get maintenance_checklist_path(record)
    assert_response :success
    assert_select "dt", text: "Aceite NUTOH46"

    patch maintenance_checklist_path(record), params: { maintenance_checklist: { operating_status: "", c2: "true" } }
    assert_redirected_to record
    assert_equal true, record.reload.c2
    assert_equal "", record.operating_status
  end

  test "the login page links to a public submission without exposing the equipment catalog or saved record" do
    @asset.update!(brand: "Marca interna")
    get login_path
    assert_select "a[href=?]", new_maintenance_checklist_path, text: /sin iniciar sesión/

    get new_maintenance_checklist_path
    assert_response :success
    assert_select "a[href=?]", mobile_assets_path, count: 0
    assert_select "a[href=?]", report_equipment_checklists_path, count: 0
    assert_select "[data-search=?]", @asset.code
    assert_select "form input[type=radio][checked]", count: 0
    refute_includes response.body, "Marca interna"

    post maintenance_checklists_path, params: { maintenance_checklist: { mobile_asset_id: 0 } }
    assert_response :unprocessable_entity
    assert_select "a[href=?]", mobile_assets_path, count: 0

    assert_difference "MaintenanceChecklist.count" do
      post maintenance_checklists_path, params: { maintenance_checklist: {
        mobile_asset_id: @asset.id, technician: "Desde terreno", operating_status: "Operativo"
      } }
      assert_response :see_other
    end
    assert_redirected_to new_maintenance_checklist_path
    follow_redirect!
    assert_select "[role=status]", text: /Checklist de mantenedor registrado/

    record = MaintenanceChecklist.find_by!(technician: "Desde terreno")
    assert_nil record.c1
    assert_nil record.c19
    get maintenance_checklist_path(record)
    assert_redirected_to login_path
    get edit_maintenance_checklist_path(record)
    assert_redirected_to login_path
    get report_equipment_checklists_path
    assert_redirected_to login_path
    get new_equipment_checklist_path
    assert_redirected_to login_path
  end

  test "the common report and CSV include both types, preserve nils and link legacy codes" do
    sign_in_with_google
    timestamp = Time.find_zone!("America/Santiago").local(2026, 11, 19, 22, 30)
    maintainer = MaintenanceChecklist.create!(
      mobile_asset: @asset, technician: "=Mantenedor", operating_status: "Fuera de servicio",
      hour_meter: "50,3", c2: nil, c19: true, nuto_oil: 23, created_at: timestamp
    )
    maintainer.update_columns(mobile_asset_id: nil, legacy_code: " hq01 ")
    operator = EquipmentChecklist.create!(EquipmentChecklist::QUESTIONS.keys.index_with { "Si" }.merge(
      mobile_asset: @asset, operator: "Operador de prueba", c17: "LCA", hour_meter: 50, created_at: timestamp
    ))

    filters = { asset_id: @asset.id, plant: "LCA", from: "2026-11-19", to: "2026-11-19" }
    get report_equipment_checklists_path, params: filters
    assert_response :success
    assert_select "td a[href=?]", maintenance_checklist_path(maintainer)
    assert_select "td a[href=?]", equipment_checklist_path(operator)

    get report_equipment_checklists_path, params: filters.merge(observations: "1")
    assert_response :success
    assert_select "td a[href=?]", maintenance_checklist_path(maintainer)
    assert_select "td a[href=?]", equipment_checklist_path(operator), count: 0

    get report_equipment_checklists_path, params: filters.merge(format: :csv)
    assert_response :success
    rows = CSV.parse(response.body.delete_prefix("\uFEFF"), col_sep: ";", headers: true)
    assert_equal %w[Mantenedor Operador], rows.map { |row| row["Tipo"] }
    assert_equal "'=Mantenedor", rows[0]["Responsable"]
    assert_equal "50,3", rows[0]["Horómetro"]
    assert_equal "Sin registro", rows[0]["Mantenedor · Revisó el nivel de aceite hidráulico y de transmisión"]
    assert_equal "23", rows[0]["Aceite NUTOH46"]
    assert_nil rows[1]["Aceite NUTOH46"]

    get mobile_asset_path(@asset)
    assert_response :success
    assert_select "td a[href=?]", maintenance_checklist_path(maintainer)
    assert_select "td a[href=?]", equipment_checklist_path(operator)
  end
end
