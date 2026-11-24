require "test_helper"
require "zip"

class TrabajosTest < ActionDispatch::IntegrationTest
  test "home report and its drill-downs use the same pending and monthly amounts" do
    travel_to Time.utc(2026, 11, 19, 15) do
      Trabajo.create!(planta: "La Calera", avance: "Terminado", fecha_termino: "2026-10-31", op: 1, q1: 1, v1: 120)
      Trabajo.create!(planta: "La Calera", avance: "Terminado", fecha_termino: "2026-10-01", op: 0, q1: 1, v1: 200)
      Trabajo.create!(planta: "La Calera", avance: "Terminado", q1: 1, v1: 300)
      Trabajo.create!(planta: "La Calera", avance: "Facturado", fecha_termino: "2026-10-31", q1: 1, v1: 400)
      Trabajo.create!(planta: "La Calera", avance: Trabajo::EN_EJECUCION, q1: 1, v1: 500)
      Trabajo.create!(planta: "Ventanas", avance: "Facturado", fecha_termino: "2026-10-31", q1: 1, v1: 600)
      sign_in_with_google(email: "jose.jerez@msindustrial.cl")

      get root_path
      assert_response :success
      assert_select "#resumen-trabajos h3", count: 4
      assert_select "#resumen-trabajos canvas", count: 0
      {
        trabajos_path(planta: "La Calera", avance: "Terminado") => "$620",
        trabajos_path(planta: "La Calera", avance: "Terminado", op: "sin") => "$500",
        trabajos_path(planta: "La Calera", avance: "Terminado", op: "con") => "$120",
        trabajos_path(planta: "La Calera", avance: Trabajo::EN_EJECUCION) => "$500",
        trabajos_path(planta: "La Calera", avance: "finalizados", mes: "2026-10") => "$720"
      }.each do |url, amount|
        assert_select "a[href=?]", url, text: amount
      end

      get trabajos_path, params: { planta: "La Calera", avance: "finalizados", mes: "2026-10" }
      assert_response :success
      assert_select "tbody tr", count: 3
      assert_select "p strong", "$720"

      get trabajos_path, params: { planta: "La Calera", avance: "Terminado", op: "con" }
      assert_response :success
      assert_select "tbody tr", count: 1
      assert_select "p strong", "$120"
    end
  end

  test "authorized users can look up a reference and preserve the imported total until its quantities or prices change" do
    id = Trabajo.insert!({ erp_id: 900, descripcion: "Reparación", q1: 2, v1: 300, total: 500 }).rows.first.first
    trabajo = Trabajo.find(id)
    sign_in_with_google(email: "fernando.gonzalez@msindustrial.cl")

    get trabajos_path, params: { q: "900" }
    assert_response :success
    assert_select "tbody a[href=?]", trabajo_path(trabajo), text: "900"

    get trabajo_path(trabajo)
    assert_response :success
    assert_select "h1", "Reparación"
    assert_select "tfoot td", "$500"

    get edit_trabajo_path(trabajo)
    assert_response :success
    assert_select "[data-item-quantity]", count: 12

    patch trabajo_path(trabajo), params: { trabajo: { op: 1234 } }
    assert_redirected_to trabajo_path(trabajo)
    assert_equal 500, trabajo.reload.total

    patch trabajo_path(trabajo), params: { trabajo: { q1: 5, total: 1, erp_id: 42 } }
    assert_redirected_to trabajo_path(trabajo)
    assert_equal 1500, trabajo.reload.total
    assert_equal 900, trabajo.erp_id
  end

  test "ERP superadmins can access the cards and the plant menus with their corporate accounts" do
    emails = %w[
      administracion@msindustrial.cl elizabeth.zuniga@msindustrial.cl fernando.gonzalez@msindustrial.cl
      jose.jerez@msindustrial.cl julio.alvear@msindustrial.cl orlando.lobos@msindustrial.cl
      simon.rojas@msindustrial.cl susana.molina@msindustrial.cl
    ]
    emails.each do |email|
      sign_in_with_google(email: email)
      get root_path
      assert_response :success
      assert_select "#resumen-trabajos", count: 1
      assert_select ".navbar a.nav-link", text: "Cotizaciones", count: 0
      assert_select 'ul[aria-labelledby="lcaDropdown"] a[href=?]', trabajos_path(planta: "La Calera"), text: "Cotizaciones"
      assert_select 'ul[aria-labelledby="ptmDropdown"] a[href=?]', trabajos_path(planta: "P.Montt"), text: "Cotizaciones"
      get trabajos_path
      assert_response :success
    end
  end

  test "authorized ERP users can create and print a quotation without a dashboard admin role" do
    sign_in_with_google(email: "elizabeth.zuniga@msindustrial.cl")
    get new_trabajo_path
    assert_response :success

    assert_difference("Trabajo.count") do
      post trabajos_path, params: { trabajo: { descripcion: "Cotización", q12: 2, v12: 250 } }
      assert_redirected_to trabajo_path(Trabajo.last)
    end
    assert_equal 500, Trabajo.last.total
    get trabajo_path(Trabajo.last)
    assert_response :success
    assert_select "button", "Imprimir cotización"

    get tasks_path
    assert_response :forbidden
  end

  test "Claudio can create quotations without seeing the home summary" do
    email = "claudio.gutierrez@msindustrial.cl"
    sign_in_with_google(email: email)

    get root_path
    assert_response :success
    assert_select "#resumen-trabajos", count: 0
    assert_select 'ul[aria-labelledby="lcaDropdown"] a[href=?]', trabajos_path(planta: "La Calera"), text: "Cotizaciones"
    assert_select 'ul[aria-labelledby="ptmDropdown"] a[href=?]', trabajos_path(planta: "P.Montt"), text: "Cotizaciones"

    get trabajos_path
    assert_response :success
    get new_trabajo_path
    assert_response :success
    assert_difference "Trabajo.count", 1 do
      post trabajos_path, params: { trabajo: { planta: "La Calera", descripcion: "Cotización de Claudio", q1: 2, v1: 250 } }
      assert_redirected_to trabajo_path(Trabajo.last)
    end
    assert_equal email, Trabajo.last.author_email
  end

  test "the Excel export keeps the filters and stored totals and includes each quotation item" do
    Trabajo.insert!({ erp_id: 901, planta: "La Calera", descripcion: "Reparación horno", avance: "Facturado",
      fecha_termino: Date.new(2026, 10, 15), op: 0, total: 500, i12: "=1+1", q12: 2, v12: 300 })
    Trabajo.create!(planta: "La Calera", descripcion: "Reparación fuera del mes", avance: "Terminado", fecha_termino: "2026-11-01")
    Trabajo.create!(planta: "La Calera", descripcion: "Reparación con OP", avance: "Terminado", fecha_termino: "2026-10-13", op: 123)
    Trabajo.create!(planta: "La Calera", descripcion: "Inspección", avance: "Terminado", fecha_termino: "2026-10-12")
    filters = { planta: "La Calera", avance: "finalizados", mes: "2026-10", q: "Reparación", op: "sin" }

    sign_in_with_google(email: "claudio.gutierrez@msindustrial.cl")
    get trabajos_path, params: filters
    assert_response :success
    assert_select "a", text: "Descargar Excel", count: 1 do |links|
      download = URI.parse(links.first["href"])
      assert_equal trabajos_path(format: :xlsx), download.path
      assert_equal filters.stringify_keys, Rack::Utils.parse_query(download.query)
    end

    get trabajos_path(format: :xlsx), params: filters.merge(page: 2)
    assert_response :success
    assert_equal "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", response.media_type
    assert_includes response.headers["Content-Disposition"], "cotizaciones-impromaq.xlsx"
    assert_includes response.headers["Cache-Control"], "no-store"

    Zip::File.open_buffer(response.body) do |workbook|
      quotations, items = [ 1, 2 ].map do |number|
        Nokogiri::XML(workbook.read("xl/worksheets/sheet#{number}.xml")).remove_namespaces!
      end
      assert_equal 2, quotations.css("sheetData row").size
      assert_equal "901", quotations.at_css('c[r="A2"]').text
      assert_equal "500", quotations.at_css('c[r="J2"] v').text
      assert_equal 2, items.css("sheetData row").size
      assert_equal "901", items.at_css('c[r="A2"]').text
      assert_equal "12", items.at_css('c[r="B2"] v').text
      assert_equal "600", items.at_css('c[r="F2"] v').text
      assert_empty items.css("f")
    end
  end

  test "Dashboard quotations export the bare reference used by numeric search" do
    quotation = Trabajo.create!(planta: "P.Montt", descripcion: "Cotización nueva", i1: "Revisión", q1: 2, v1: 50)
    reference = quotation.id.to_s
    sign_in_with_google(email: "claudio.gutierrez@msindustrial.cl")

    [ reference, quotation.referencia ].each do |query|
      get trabajos_path, params: { planta: "P.Montt", q: query }
      assert_response :success
      assert_select "tbody a[href=?]", trabajo_path(quotation), count: 1
    end

    get trabajos_path(format: :xlsx), params: { planta: "P.Montt", q: reference }
    assert_response :success
    Zip::File.open_buffer(response.body) do |workbook|
      [ 1, 2 ].each do |number|
        sheet = Nokogiri::XML(workbook.read("xl/worksheets/sheet#{number}.xml")).remove_namespaces!
        assert_equal reference, sheet.at_css('c[r="A2"]').text
      end
    end
  end

  test "unlisted accounts cannot open or submit any jobs or quotations" do
    imported = Trabajo.create!(erp_id: 567, descripcion: "Trabajo histórico")
    own = Trabajo.create!(author_email: "usuario@msindustrial.cl", descripcion: "Cotización anterior")
    get trabajos_path
    assert_redirected_to login_path
    get trabajos_path(format: :xlsx)
    assert_redirected_to login_path
    sign_in_with_google

    get root_path
    assert_select "#resumen-trabajos", count: 0
    assert_select ".navbar a", text: "Cotizaciones", count: 0
    [ trabajos_path, trabajos_path(format: :xlsx), new_trabajo_path, trabajo_path(imported), trabajo_path(own), edit_trabajo_path(own) ].each do |path|
      get path
      assert_response :forbidden
    end

    assert_no_difference("Trabajo.count") do
      post trabajos_path, params: { trabajo: { descripcion: "Cotización", q12: 2, v12: 250 } }
      assert_response :forbidden
    end
    patch trabajo_path(own), params: { trabajo: { descripcion: "Cambio" } }
    assert_response :forbidden
    assert_equal "Cotización anterior", own.reload.descripcion
  end
end
