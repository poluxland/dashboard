require "test_helper"
require "zip"

class PmmTrucksTest < ActionDispatch::IntegrationTest
  setup do
    @today = Time.current.in_time_zone(PmmTruck::CHILE).to_date
    @material = PmmMaterial.create!(nombre: "Conchuela", densidad: 1)
    @legacy = PmmTruck.create!(pmm_id: 125, fecha: @today, pmm_material: @material, patente: "ABC123",
      tipo: "Plano", llegada: "08:00", salida: "00:00", wait: -480, motive: "=1+1")
  end

  test "public views render while general editing and private reports require a corporate account" do
    get login_path
    assert_response :success
    assert_select ".login-card a[href=?]", pmm_trucks_path, text: "Camiones en planta", count: 1

    get pmm_trucks_path
    assert_response :success
    assert_select "section[aria-label='Camiones sin salida']", text: /ABC123/
    get month_pmm_trucks_path
    assert_response :success

    [ edit_pmm_truck_path(@legacy), pmm_truck_path(@legacy), history_pmm_trucks_path,
      report_pmm_trucks_path, arrivals_pmm_trucks_path, annual_pmm_trucks_path, pmm_catalog_path("materias") ].each do |path|
      get path
      assert_redirected_to login_path
    end
    patch pmm_truck_path(@legacy), params: { pmm_truck: { salida: "09:00" } }
    assert_redirected_to login_path
    assert_equal(-480, @legacy.reload.wait)
  end

  test "a visitor can register an arrival and close it with only the departure time" do
    get new_pmm_truck_path
    assert_response :success

    assert_difference "PmmTruck.count" do
      post pmm_trucks_path, params: { pmm_truck: valid_fields }
    end
    truck = PmmTruck.find_by!(patente: "XY1234")
    assert_redirected_to pmm_trucks_path
    follow_redirect!
    assert_select "section[aria-label='Camiones sin salida'] a[href=?]", departure_pmm_truck_path(truck), text: "Registrar salida"

    get departure_pmm_truck_path(truck)
    assert_response :success
    assert_select "input[name='pmm_truck[salida]']", count: 1

    patch departure_pmm_truck_path(truck), params: { pmm_truck: { salida: "" } }
    assert_response :unprocessable_entity
    assert truck.reload.pending?

    patch departure_pmm_truck_path(truck), params: { pmm_truck: { salida: "00:10", patente: "ALTERADA" } }
    assert_redirected_to pmm_trucks_path
    assert_equal 20, truck.reload.wait
    assert_equal "XY1234", truck.patente
    refute truck.pending?

    patch departure_pmm_truck_path(truck), params: { pmm_truck: { salida: "01:30" } }
    assert_redirected_to pmm_trucks_path
    assert_equal "00:10", truck.reload.salida.strftime("%H:%M")
  end

  test "a visitor can close an imported truck at midnight but cannot close archived arrivals" do
    old = @legacy.dup
    old.update!(pmm_id: 124, fecha: @today.yesterday)
    patch departure_pmm_truck_path(old), params: { pmm_truck: { salida: "09:00" } }
    assert_redirected_to pmm_trucks_path
    assert_equal(-480, old.reload.wait)

    patch departure_pmm_truck_path(@legacy), params: { pmm_truck: { salida: "00:00" } }
    assert_redirected_to pmm_trucks_path
    assert_equal 960, @legacy.reload.wait
    refute @legacy.pending?
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

  test "arrivals report filters measured records and draws arrival bands and calendar totals" do
    other = PmmMaterial.create!(nombre: "Fierro")
    PmmTruck.create!(fecha: @today, llegada: "05:10", salida: "05:40", wait: 30, finished: true,
      pmm_material: @material, tipo: "Plano", cause: "Normal", patente: "REP101", motive: "Ingreso por cancha norte")
    PmmTruck.create!(fecha: @today, llegada: "05:45", salida: "07:15", wait: 90, finished: true,
      pmm_material: @material, tipo: "Plano", cause: "sin BRU", patente: "REP102")
    PmmTruck.create!(fecha: @today, llegada: "06:15", salida: "07:15", wait: 60, finished: true,
      pmm_material: other, tipo: "Batea 20", cause: "Normal", patente: "REP103")
    PmmTruck.create!(fecha: @today, llegada: "05:20", finished: false,
      pmm_material: @material, tipo: "Plano", cause: "Normal", patente: "PEND01")
    sign_in_with_google

    get arrivals_pmm_trucks_path, params: { from: @today, to: @today, band: "30", group: "week", observations: "special" }
    assert_response :success
    assert_select "h1", "Llegada de camiones por materia prima"
    assert_select "table[aria-label='Comentarios de camiones'] tbody tr", count: 2
    assert_select "table[aria-label='Por materia prima'] tbody tr", count: 2
    assert_select "[data-pmm-truck-charts-charts-value]", count: 1 do |elements|
      hour, week = JSON.parse(elements.first["data-pmm-truck-charts-charts-value"])
      assert_equal [ "05:00–05:30", "05:30–06:00", "06:00–06:30" ], hour["labels"]
      assert_equal [ 30.0, 90.0, 60.0 ], hour["series"].last["data"]
      assert_equal [ 3 ], week["series"].first["data"]
      assert_equal [ 60.0 ], week["series"].last["data"]
    end

    get arrivals_pmm_trucks_path, params: { from: @today, to: @today, time_from: "300", time_to: "360",
      material_ids: [ @material.id ], types: [ "Plano" ], statuses: [ "Normal" ], q: "cancha" }
    assert_response :success
    assert_select "table[aria-label='Comentarios de camiones'] tbody tr", count: 1, text: /REP101.*Ingreso por cancha norte/m
    assert_select "table[aria-label='Por estado del registro'] tbody tr.table-primary", count: 1
    assert_select "[data-pmm-truck-charts-charts-value]", count: 1 do |elements|
      hourly = JSON.parse(elements.first["data-pmm-truck-charts-charts-value"]).first
      assert_equal [ 1 ], hourly["series"].first["data"]
      assert_equal [ 30.0 ], hourly["series"].last["data"]
    end

    get arrivals_pmm_trucks_path, params: { time_from: "720", time_to: "300" }
    assert_redirected_to arrivals_pmm_trucks_path
  end

  test "only administrators have a confirmed delete action in the truck edit page" do
    sign_in_with_google(email: "jose.jerez@msindustrial.cl")
    get pmm_truck_path(@legacy)
    assert_response :success
    assert_select "button", text: "Eliminar registro", count: 0

    get edit_pmm_truck_path(@legacy)
    assert_response :success
    assert_select "form[data-turbo-confirm][action=?]", pmm_truck_path(@legacy), count: 1 do
      assert_select "input[name='_method'][value='delete']", count: 1
      assert_select "button", text: "Eliminar registro", count: 1
    end

    sign_in_with_google
    get edit_pmm_truck_path(@legacy)
    assert_response :success
    assert_select "button", text: "Eliminar registro", count: 0
    assert_no_difference "PmmTruck.count" do
      delete pmm_truck_path(@legacy)
    end
    assert_response :forbidden
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
