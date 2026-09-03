require "test_helper"

class MantencionesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_with_google
    @mantencion = mantenciones(:one)
  end

  test "muestra el listado y el acceso desde Informe" do
    get mantenciones_url

    assert_response :success
    assert_select "h1", text: "Mantenciones"
    assert_select "tbody tr[id^='mantencion_']", count: 2
    assert_select "a[href=?]", mantenciones_path, text: "Mantenciones"
    assert_select "a[href=?]", mantenciones_path(especialidad: "electrica"), text: "M. Eléctrica"
    assert_select "a[href=?]", mantenciones_path(especialidad: "mecanica"), text: "M. Mecánica"
    assert_select "a[href=?]", graficos_mantenciones_path, text: "Gráficos de mantenciones"
    assert_select "a[href=?]", graficos_mantenciones_path, text: "Ver gráficos"
  end

  test "muestra los gráficos y agrupa categorías normalizadas" do
    @mantencion.update_column(:planificacion, " plan ")
    Mantencion.create!(
      semana: 37,
      fecha: Date.new(2026, 9, 9),
      especialidad: "ELÉCTRICA",
      area: "p416",
      codigo: "wt02",
      tipo_mantencion: "preventivo",
      actividad: "Prueba semanal",
      planificacion: "PLAN",
      estado: 100,
      duracion: 2
    )

    get graficos_mantenciones_url

    assert_response :success
    assert_select "h1", text: "Gráficos de mantenciones"
    assert_select "canvas", count: 8
    assert_select "#mantencionesPlanificacionChartCard .chart-data li", text: "Plan: 2"
    assert_select "#mantencionesEspecialidadChartCard .chart-data li", text: "Eléctrico: 2"
    assert_select "#mantencionesAreaChartCard .chart-data li", text: "P416: 2"
  end

  test "filtra los gráficos por especialidad y año" do
    get graficos_mantenciones_url(especialidad: "mecanica", year: 2026)

    assert_response :success
    assert_select "select[name='especialidad'] option[selected][value='mecanica']"
    assert_select "select[name='year'] option[selected][value='2026']"
    assert_select "#mantencionesEspecialidadChartCard .chart-data li", text: "Mecánico: 1"
  end

  test "filtra las mantenciones eléctricas" do
    get mantenciones_url(especialidad: "electrica")

    assert_response :success
    assert_select "h1", text: "Mantención eléctrica"
    assert_select "#mantencion_#{mantenciones(:one).id}", count: 1
    assert_select "#mantencion_#{mantenciones(:two).id}", count: 0
  end

  test "filtra las mantenciones mecánicas" do
    get mantenciones_url(especialidad: "mecanica")

    assert_response :success
    assert_select "h1", text: "Mantención mecánica"
    assert_select "#mantencion_#{mantenciones(:one).id}", count: 0
    assert_select "#mantencion_#{mantenciones(:two).id}", count: 1
  end

  test "muestra el formulario con todas las columnas del informe" do
    get new_mantencion_url

    assert_response :success
    assert_select "input[name='mantencion[fecha]'][value=?]", Time.find_zone!("America/Santiago").today.iso8601
    %w[
      semana fecha especialidad area codigo tipo_mantencion actividad
      planificacion estado numero_ot duracion comentarios
    ].each do |field|
      assert_select "[name='mantencion[#{field}]']", count: 1
    end
  end

  test "preselecciona especialidad mecánica desde su filtro" do
    get new_mantencion_url(especialidad: "mecanica")

    assert_response :success
    assert_select "input[name='mantencion[especialidad]'][value='Mecánico']", count: 1
  end

  test "crea una mantención" do
    assert_difference("Mantencion.count") do
      post mantenciones_url, params: {
        mantencion: {
          semana: 37,
          fecha: "2026-09-09",
          especialidad: "Eléctrico",
          area: "P513",
          codigo: "PM01",
          tipo_mantencion: "Preventivo",
          actividad: "Mantención de equipo",
          planificacion: "Plan",
          estado: 75,
          numero_ot: "55390000",
          duracion: 2.5,
          comentarios: "Pendiente de prueba final"
        }
      }
    end

    mantencion = Mantencion.order(:created_at).last
    assert_redirected_to mantenciones_url
    assert_equal "55390000", mantencion.numero_ot
    assert_equal "P513", mantencion.area
    assert_equal 75, mantencion.estado
  end

  test "rechaza una mantención inválida" do
    assert_no_difference("Mantencion.count") do
      post mantenciones_url, params: {
        mantencion: { fecha: "", especialidad: "", actividad: "" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "muestra una mantención" do
    get mantencion_url(@mantencion)

    assert_response :success
    assert_select "h1", text: "Detalle de mantención"
  end

  test "muestra el formulario de edición" do
    get edit_mantencion_url(@mantencion)

    assert_response :success
  end

  test "actualiza una mantención" do
    patch mantencion_url(@mantencion), params: {
      mantencion: { estado: 80, comentarios: "Trabajo avanzado" }
    }

    assert_redirected_to mantenciones_url
    assert_equal 80, @mantencion.reload.estado
    assert_equal "Trabajo avanzado", @mantencion.comentarios
  end

  test "elimina una mantención" do
    assert_difference("Mantencion.count", -1) do
      delete mantencion_url(@mantencion)
    end

    assert_redirected_to mantenciones_url
  end
end
