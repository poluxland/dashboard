require "test_helper"

class EquipmentChecklistsTest < ActionDispatch::IntegrationTest
  setup do
    @asset = MobileAsset.create!(code: "HQ01", plant: "LCA")
  end

  teardown do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  test "the checklist form uses radio choices and saves a complete inspection" do
    sign_in_with_google

    get new_equipment_checklist_path(asset_id: @asset.id)
    assert_response :success
    assert_select "form select", count: 0
    assert_select "input[type=radio][name='equipment_checklist[c1]']", count: 4

    assert_no_difference "EquipmentChecklist.count" do
      post equipment_checklists_path, params: { equipment_checklist: { mobile_asset_id: @asset.id } }
      assert_response :unprocessable_entity
    end

    answers = EquipmentChecklist::QUESTIONS.keys.index_with { "Si" }.merge(c3: "No(grave)")
    assert_difference "EquipmentChecklist.count" do
      post equipment_checklists_path, params: { equipment_checklist: answers.merge(
        mobile_asset_id: @asset.id, operator: "Operador de prueba", hour_meter: 120, c17: "LCA"
      ) }
      assert_response :redirect
    end

    follow_redirect!
    assert_response :success
    assert_select ".badge", text: "Con falla grave"
  end

  test "historical records without a link appear in the equipment history and report" do
    sign_in_with_google
    chile = Time.find_zone!("America/Santiago")
    early = chile.local(2026, 11, 17, 23, 45)
    inside = chile.local(2026, 11, 18, 23, 45)
    late = chile.local(2026, 11, 19)
    historical = { mobile_asset_id: nil, legacy_code: " hq01 ", c17: "LCA", c2: "No", hour_meter: 140 }
    EquipmentChecklist.insert_all!([
      historical.merge(operator: "Previo", created_at: early),
      historical.merge(operator: "Histórico", created_at: inside),
      historical.merge(operator: "Posterior", created_at: late),
      historical.merge(operator: "Otro equipo", legacy_code: "HQ02", created_at: inside),
      historical.merge(operator: "Asignado a otro equipo", mobile_asset_id: MobileAsset.create!(code: "HQ03").id, created_at: inside)
    ])
    legacy = EquipmentChecklist.find_by!(operator: "Histórico")

    get edit_equipment_checklist_path(legacy)
    assert_response :success
    assert_select "input[type=radio][name='equipment_checklist[c2]'][value='No'][checked]"
    patch equipment_checklist_path(legacy), params: { equipment_checklist: { comments: "Revisar durante el turno" } }
    assert_redirected_to legacy
    assert_equal "No", legacy.reload.c2
    assert_nil legacy.mobile_asset_id

    filters = { asset_id: @asset.id, plant: "LCA", from: "2026-11-18", to: "2026-11-18", status: "leve" }
    get report_equipment_checklists_path, params: filters
    assert_response :success
    assert_select "td", text: "Histórico", count: 1
    assert_select "td", text: /Previo|Posterior|Otro equipo|Asignado/, count: 0

    get equipment_checklists_path(format: :xlsx), params: filters
    assert_response :success
    assert_equal "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", response.media_type
    assert response.body.start_with?("PK")
  end

  test "fleet and history require Dashboard login" do
    get mobile_assets_path
    assert_redirected_to login_path
    get equipment_checklists_path
    assert_redirected_to login_path
    get report_equipment_checklists_path
    assert_redirected_to login_path
  end
end
