require "test_helper"

class SopladosTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  test "the login links to the public form below the operator checklist" do
    get login_path
    assert_response :success
    assert_select ".login-card .border-top a", count: 2 do |links|
      assert_equal [ new_equipment_checklist_path, new_soplado_path ], links.map { |link| link["href"] }
      assert_equal "Registro soplado TC", links.last.text
    end

    get new_soplado_path
    assert_response :success
    assert_select "h1", "Registro soplado TC"
    Soplado::LABELS.each_key do |field|
      assert_select "[name=?]", "soplado[#{field}]", count: 1
    end
  end

  test "a visitor can save a record in Chilean time without receiving access to its detail" do
    attrs = { supervisor: "Supervisor de turno", fecha: "2026-11-16T14:35", presion2: "2,5",
              presion3: "-1.25", horno: "0", jetin: "false", tiempo: "25", operadores: "2", erp_id: 123 }
    assert_enqueued_emails 1 do
      assert_difference("Soplado.count") { post soplados_path, params: { soplado: attrs } }
    end
    assert_redirected_to new_soplado_path
    assert_response :see_other
    record = Soplado.last
    assert_equal Time.utc(2026, 11, 16, 17, 35), record.fecha.utc
    assert_equal 2.5, record.presion2
    assert_equal(-1.25, record.presion3)
    assert_equal 0.0, record.horno
    assert_equal false, record.jetin
    assert_nil record.erp_id
    follow_redirect!
    assert_select ".alert-success", /Registro de soplado TC guardado/

    [ soplados_path, soplado_path(record), edit_soplado_path(record), graficos_soplados_path ].each do |path|
      get path
      assert_redirected_to login_path
    end
    patch soplado_path(record), params: { soplado: { supervisor: "Otro operador" } }
    assert_redirected_to login_path
    assert_equal "Supervisor de turno", record.reload.supervisor
  end

  test "invalid measurements are rejected before a notification is queued" do
    assert_no_enqueued_emails do
      assert_no_difference("Soplado.count") do
        post soplados_path, params: { soplado: { supervisor: "Operador", fecha: "2026-11-16T14:35", presion5: "texto" } }
      end
    end
    assert_response :unprocessable_entity
    assert_select ".alert-danger"
  end

  test "the signed-in history filters by the Chilean date and allows editing the full record" do
    first = Soplado.create!(fecha: Time.utc(2026, 11, 17, 2, 30), supervisor: "Uno", carbon_horno: 2.4)
    Soplado.create!(fecha: Time.utc(2026, 11, 17, 3, 30), supervisor: "Dos")
    sign_in_with_google
    get soplados_path, params: { desde: "2026-11-16", hasta: "2026-11-16" }
    assert_response :success
    assert_select "tbody tr", count: 1
    assert_select "tbody td", "16/11/2026 23:30"
    assert_select "tbody td", "Uno"
    assert_select "a[href=?]", graficos_soplados_path, text: "Gráficos"

    get edit_soplado_path(first)
    assert_response :success
    assert_select 'input[name="soplado[fecha]"][value="2026-11-16T23:30"]'
    patch soplado_path(first), params: { soplado: { carbon_precalcinador: "4,25", operadores: "4", mirillas: "Operativas" } }
    assert_redirected_to soplado_path(first)
    follow_redirect!
    assert_select "dt", "Carbón precalcinador (t/h)"
    assert_select "dd", "4.25"
    assert_select "dd", "Operativas"
    assert_equal 4, first.reload.operadores

    assert_no_difference("Soplado.count") { delete soplado_path(first) }
    assert_response :forbidden
  end

  test "the charts include the ERP measurements and keep zero values" do
    travel_to Time.utc(2026, 11, 19, 15) do
      sample = Soplado.create!(fecha: 2.days.ago, supervisor: "Uno", horno: 120, presion2: 0, presion5: 850)
      Soplado.create!(fecha: 2.years.ago, supervisor: "Anterior", horno: 100)
      sign_in_with_google
      get graficos_soplados_path
      assert_response :success
      assert_select "canvas", count: 3
      assert_select "[data-soplados-charts-series-value]" do |charts|
        series = JSON.parse(charts.first["data-soplados-charts-series-value"])
        assert_equal [ [ sample.fecha.to_i * 1000, 120.0 ] ], series["horno"]
        assert_equal [ [ sample.fecha.to_i * 1000, 0.0 ] ], series["presion2"]
        assert_equal [ [ sample.fecha.to_i * 1000, 850.0 ] ], series["presion5"]
      end
    end
  end

  test "history exports keep the filters and protect spreadsheet cells from formulas" do
    Soplado.create!(fecha: Time.utc(2026, 11, 16, 15), supervisor: "Turno A", observaciones: "=1+1", horno: 120)
    Soplado.create!(fecha: Time.utc(2026, 11, 17, 15), supervisor: "Turno B", horno: 130)
    sign_in_with_google

    filters = { desde: "2026-11-16", hasta: "2026-11-16" }
    get soplados_path(format: :csv), params: filters
    assert_response :success
    csv = CSV.parse(response.body.delete_prefix("\uFEFF"), col_sep: ";", headers: true)
    assert_equal [ "Turno A" ], csv.map { |row| row["Supervisor"] }
    assert_equal "'=1+1", csv.first["Observaciones"]
    assert_equal "120.0", csv.first["Alimentación horno (t/h)"]

    get soplados_path(format: :xlsx), params: filters
    assert_response :success
    Zip::File.open_buffer(response.body) do |zip|
      worksheet = zip.read("xl/worksheets/sheet1.xml")
      assert_includes worksheet, "Turno A"
      assert_not_includes worksheet, "Turno B"
      refute_match(/<f[ >]/, worksheet)
    end

    get soplados_path, params: filters.merge(vista: "impresion")
    assert_response :success
    assert_select ".soplados-print table tbody tr", count: 1
    assert_select ".soplados-print table th", text: "Acciones", count: 0
  end

  test "mail includes previous readings and preserves the ERP morning recipient" do
    at = Time.utc(2026, 11, 17, 11)
    Soplado.create!(fecha: at - 1.day, created_at: at - 1.day, supervisor: "Anterior")
    latest = Soplado.create!(fecha: at, created_at: at, supervisor: "Matinal", jetin: true, carbon_horno: 4)
    Soplado.create!(fecha: at + 1.day, created_at: at + 1.day, supervisor: "Posterior")
    mail = SopladoMailer.report(latest).message
    assert_includes mail.to, "helmut.brandau@meloncementos.cl"
    assert_includes mail.html_part.decoded, "Matinal"
    assert_includes mail.html_part.decoded, "Anterior"
    assert_not_includes mail.html_part.decoded, "Posterior"
    assert_includes mail.text_part.decoded, "Jetin: Sí"
  end
end
