require "test_helper"
require_relative "../../db/migrate/20261002190100_assign_ptm_roster"

class IndicatorParticipationTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_with_google
    @existing = people(:one)
    @new_person = Person.create!(name: "Nueva persona PTM", area: "Envasado PTM", planta: "PTM")
  end

  test "new people are excluded from indicators but available for shift reports" do
    assert_not @new_person.indicator_enabled?
    get matrix_indicator_readings_path
    assert_response :success
    assert_select "td", text: @existing.name
    assert_select "td", text: @new_person.name, count: 0
    get new_indicator_reading_path
    assert_select "option[value='#{@new_person.id}']", count: 0
    get new_shift_report_path
    assert_select "input[value='#{@new_person.id}']", count: 1
  end

  test "cannot submit excluded people individually or through bulk upsert" do
    assert_no_difference("IndicatorReading.count") do
      post indicator_readings_path, params: { indicator_reading: {
        person_id: @new_person.id, period: "2026-10", cuasi: 1, lvs: 1, cc: 1, hh: 1
      } }
      assert_response :unprocessable_entity
      post matrix_save_indicator_readings_path, params: { month: "2026-10", rows: {
        @existing.id => { cuasi: 1, lvs: 1, cc: 1, hh: 1 },
        @new_person.id => { cuasi: 1, lvs: 1, cc: 1, hh: 1 }
      } }
      assert_redirected_to matrix_indicator_readings_path(month: "2026-10")
      assert_match "no participan", flash[:alert]
    end
  end

  test "participation can be changed through people form and historical readings are retained" do
    patch person_path(@new_person), params: { person: { indicator_enabled: "1" } }
    assert @new_person.reload.indicator_enabled?
    get matrix_indicator_readings_path
    assert_select "td", text: @new_person.name
    count = @existing.indicator_readings.count
    patch person_path(@existing), params: { person: { indicator_enabled: "0" } }
    assert_not @existing.reload.indicator_enabled?
    assert_equal count, @existing.indicator_readings.count
    get indicator_readings_path(month: "2025-09")
    assert_response :success
    assert_not_includes response.body, @existing.name
  end

  test "roster migration matches accents preserves eligibility and is idempotent" do
    @existing.update!(name: "  Hector ampuero  ")
    migration = AssignPtmRoster.new
    assert_difference("Person.count", 43) { migration.up }
    assert_equal "Adicionales PTM", @existing.reload.area
    assert @existing.indicator_enabled?
    assert_equal 44, Person.where(planta: "PTM").where.not(id: @new_person.id).count
    assert_not Person.find_by!(name: "Miguel Levin").indicator_enabled?
    assert_no_difference("Person.count") { migration.up }
    assert_equal 2, Person.for_indicators.count
  end
end
