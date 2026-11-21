require "test_helper"
require "zip"

class PmmTrucksTest < ActionDispatch::IntegrationTest
  setup do
    @today = Time.current.in_time_zone(PmmTruck::CHILE).to_date
    @material = PmmMaterial.create!(nombre: "Conchuela", densidad: 1)
    @legacy = PmmTruck.create!(pmm_id: 125, fecha: @today, pmm_material: @material, patente: "ABC123",
      tipo: "Plano", llegada: "08:00", salida: "00:00", wait: -480, motive: "=1+1")
  end

  test "the public views render while the operating records require a corporate account" do
    get pmm_trucks_path
    assert_response :success
    assert_select "section[aria-label='Camiones sin salida']", text: /ABC123/
    get month_pmm_trucks_path
    assert_response :success

    [ new_pmm_truck_path, edit_pmm_truck_path(@legacy), pmm_truck_path(@legacy), history_pmm_trucks_path,
      report_pmm_trucks_path, annual_pmm_trucks_path, pmm_catalog_path("materias") ].each do |path|
      get path
      assert_redirected_to login_path
    end
    assert_no_difference "PmmTruck.count" do
      post pmm_trucks_path, params: { pmm_truck: valid_fields }
    end
    assert_redirected_to login_path
  end

  test "capturing and closing a truck computes minutes across midnight while retaining imported values" do
    sign_in_with_google
    get new_pmm_truck_path
    assert_response :success
    assert_difference "PmmTruck.count" do
      post pmm_trucks_path, params: { pmm_truck: valid_fields }
    end
    truck = PmmTruck.find_by!(patente: "XY1234")
    assert_redirected_to pmm_truck_path(truck)
    assert truck.pending?
    assert_nil truck.wait

    get pmm_truck_path(truck)
    assert_response :success
    patch pmm_truck_path(truck), params: { pmm_truck: { salida: "00:10" } }
    assert_redirected_to pmm_truck_path(truck)
    assert_equal 20, truck.reload.wait
    refute truck.pending?
    assert_equal(-480, @legacy.reload.wait)

    get history_pmm_trucks_path, params: { patente: "xy12", from: @today.iso8601, to: @today.iso8601 }
    assert_response :success
    assert_select "tbody tr", count: 1, text: /XY1234/
    assert_not_includes response.body, "ABC123"
  end

  test "Excel preserves imported data and escapes strings that could become formulas" do
    get pmm_trucks_path(format: :xlsx)
    assert_response :success
    assert_equal "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", response.media_type
    Zip::File.open_buffer(response.body) do |workbook|
      worksheet = workbook.read("xl/worksheets/sheet1.xml")
      strings = workbook.glob("xl/sharedStrings.xml").first&.get_input_stream&.read.to_s
      assert_includes "#{worksheet} #{strings}", "ABC123"
      assert_includes worksheet, "-480"
      refute_match(/<f[ >]/, worksheet)
    end
  end

  test "reports include completed waits and BRU visits, and catalogs reference the imported material" do
    PmmTruck.create!(pmm_id: 126, fecha: @today, pmm_material: @material, patente: "FIN123",
      tipo: "Plano", llegada: "08:00", salida: "09:00", wait: 60)
    PmmBruVisit.create!(pmm_id: 5, fecha: @today, mmpp: "Conchuela")

    sign_in_with_google
    get report_pmm_trucks_path
    assert_response :success
    assert_select "h2", text: "Registros BRU por día"
    assert_match(/1 camiones · 60 min/, response.body)
    get annual_pmm_trucks_path, params: { year: @today.year }
    assert_response :success
    assert_select "h2", text: "Conchuela por tipo de camión"

    get new_pmm_catalog_entry_path("canchas")
    assert_response :success
    assert_difference "PmmYard.count" do
      post pmm_catalog_path("canchas"), params: { record: { nombre: "Patio norte", pmm_material_id: @material.id, operativa: "true" } }
    end
    assert_redirected_to pmm_catalog_path("canchas")
    follow_redirect!
    assert_response :success
    assert_select "tbody tr", text: /Patio norte.*Conchuela/m
  end

  test "the scheduled truck email keeps the source audience and sends once per slot" do
    slot = Time.utc(2026, 11, 20, 12, 30)
    assert_no_difference -> { ActionMailer::Base.deliveries.size } do
      PmmTruckReportDelivery.dispatch_due(reference_time: slot + 1.minute, start_at: nil, utc_times: "12:30")
    end
    assert_difference -> { ActionMailer::Base.deliveries.size }, 1 do
      2.times do
        PmmTruckReportDelivery.dispatch_due(reference_time: slot + 1.minute, start_at: slot.iso8601, utc_times: "12:30")
      end
    end
    message = ActionMailer::Base.deliveries.last
    assert_equal 16, message.to.size
    assert_includes message.text_part.decoded, "http://example.com/camiones"
    assert_includes message.html_part.decoded, "Resumen BRU"
  end

  test "the annual report compares integer waits to a fractional outlier threshold" do
    [ *Array.new(19, 60), 300 ].each do |wait|
      PmmTruck.create!(pmm_material: @material, fecha: @today, tipo: "Plano", wait: wait, finished: true)
    end

    assert_equal 1, PmmTruckReport.new(@today).annual(@today.year).fetch(:flatbed_outliers)
  end

  private

  def valid_fields
    { fecha: @today.iso8601, pmm_material_id: @material.id, patente: " xy1234 ", tipo: "Plano", llegada: "23:50" }
  end
end
