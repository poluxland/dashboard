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
    assert_select "a[href=?]", pendientes_mantenciones_path, text: "Pendientes"
    assert_select "a[href=?]", graficos_mantenciones_path, text: "Ver gráficos"
    assert_select "th", text: "Duración del trabajo"
  end

  test "desglose cuenta los tipos solo dentro del Plan y conserva otras planificaciones" do
    Mantencion.create!(fecha: Date.new(2026, 9, 9), especialidad: "Eléctrico",
                       actividad: "Reprogramada", planificacion: "Reprogramado")
    Mantencion.create!(fecha: Date.new(2026, 9, 9), especialidad: "Eléctrico",
                       actividad: "Correctivo del plan", planificacion: "Plan",
                       tipo_mantencion: "Correctivo No programado")
    get desglose_mantenciones_url
    assert_response :success
    assert_select "a.active[href=?]", desglose_mantenciones_path, text: "Desglose"
    assert_select "#breakdown-total .breakdown-count", text: "4"
    assert_select "[data-planning='Plan']", text: /50% del total/
    assert_select "[data-planning='Adicional'] .breakdown-count", text: "1"
    assert_select "[data-planning='Reprogramado'] .breakdown-count", text: "1"
    assert_select "[data-maintenance-type='Preventiva']", text: /50% del Plan.*25% del total/m
    assert_select "[data-maintenance-type='Correctivo Programado'] .breakdown-count", text: "0"
    assert_select "[data-maintenance-type='Correctivo No programado'] .breakdown-count", text: "1"
  end

  test "desglose filtra y maneja un Plan vacío o un total vacío" do
    get desglose_mantenciones_url(especialidad: "mecanica", year: 2026, semana: 36)
    assert_response :success
    assert_select "#breakdown-total .breakdown-count", text: "1"
    assert_select "[data-planning='Plan'] .breakdown-count", text: "0"
    assert_select "[data-maintenance-type] span", text: "0% del Plan", count: 3
    assert_select "select[name='especialidad'] option[selected][value='mecanica']"
    assert_select "form[action=?]", desglose_mantenciones_path

    get desglose_mantenciones_url(year: 2000)
    assert_response :success
    assert_select "#breakdown-total .breakdown-count", text: "0"
    assert_select ".alert-info", text: "No hay tareas para los filtros seleccionados."
  end

  test "desglose incluye los extremos del tramo entre años y recalcula porcentajes" do
    [
      [ 2025, 1, "Plan", "Preventiva", "Eléctrico" ],
      [ 2025, 2, "Plan", "Preventiva", "Eléctrico" ],
      [ 2025, 30, "Plan", "Correctivo Programado", "Eléctrico" ],
      [ 2026, 10, "Adicional", "Correctivo No programado", "Mecánico" ],
      [ 2026, 11, "Plan", "Preventiva", "Eléctrico" ]
    ].each do |year, week, planning, type, specialty|
      Mantencion.create!(fecha: Date.commercial(year, week, 3), semana: week,
                         actividad: "Tarea del tramo", especialidad: specialty,
                         planificacion: planning, tipo_mantencion: type)
    end
    filters = { desde_year: 2025, desde_semana: 2, hasta_year: 2026, hasta_semana: 10 }
    get desglose_mantenciones_url(**filters)
    assert_response :success
    assert_select "#breakdown-total .breakdown-count", text: "3"
    assert_select "[data-planning='Plan'] .breakdown-count", text: "2"
    assert_select "[data-planning='Plan']", text: /66[,.]7% del total/
    assert_select "[data-planning='Adicional'] .breakdown-count", text: "1"
    assert_select "[data-maintenance-type='Preventiva']", text: /50% del Plan.*33[,.]3% del total/m
    filters.each do |key, value|
      assert_select "select[name='#{key}'] option[selected][value='#{value}']"
    end

    get desglose_mantenciones_url(**filters, especialidad: "electrica")
    assert_select "#breakdown-total .breakdown-count", text: "2"
    assert_select "[data-planning='Plan']", text: /100% del total/

    get desglose_mantenciones_url(desde_year: 2026, desde_semana: 10, hasta_year: 2026, hasta_semana: 10)
    assert_select "#breakdown-total .breakdown-count", text: "1"
    assert_select "[data-planning='Plan'] .breakdown-count", text: "0"
  end

  test "desglose valida rangos incompletos invertidos e inválidos" do
    [
      { desde_year: 2025 },
      { desde_year: 2026, desde_semana: 11, hasta_year: 2026, hasta_semana: 10 },
      { desde_year: 2026, desde_semana: 54, hasta_year: 2026, hasta_semana: 55 },
      { desde_year: "error", desde_semana: 1, hasta_year: 2026, hasta_semana: 10 }
    ].each do |filters|
      get desglose_mantenciones_url(**filters)
      assert_response :success
      assert_select ".alert-warning", count: 1
      assert_select "#breakdown-total", count: 0
    end

    get desglose_mantenciones_url(desde_year: "", desde_semana: "", hasta_year: "", hasta_semana: "")
    assert_select ".alert-warning", count: 0
    assert_select "#breakdown-total .breakdown-count", text: "2"
  end

  test "muestra solamente las mantenciones pendientes" do
    without_state = Mantencion.create!(
      fecha: Date.new(2026, 9, 4),
      especialidad: "Eléctrico",
      actividad: "Tarea sin estado"
    )

    get pendientes_mantenciones_url

    assert_response :success
    assert_select "h1", text: "Mantenciones pendientes"
    assert_select "#mantencion_#{mantenciones(:one).id}", count: 0
    assert_select "#mantencion_#{mantenciones(:two).id}", count: 1
    assert_select "#mantencion_#{without_state.id}", count: 1
    assert_select "a[href=?].active", pendientes_mantenciones_path, text: "Pendientes"
  end

  test "muestra los gráficos y agrupa categorías normalizadas" do
    @mantencion.update!(planificacion: " plan ")
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
    assert_select "#mantencionesPlanificacionBarrasChartCard .chart-data li", text: "Plan: 66.7"
    assert_select "#mantencionesPlanificacionBarrasChartCard .chart-data li", text: "Adicional: 33.3"
    assert_select "#mantencionesPlanificacionChartCard .chart-data li", text: "Plan: 2"
    assert_select "#mantencionesEspecialidadChartCard .chart-data li", text: "Eléctrico: 2"
    assert_select "#mantencionesAreaChartCard .chart-data li", text: "P416: 2"
    assert_select "#mantencionesWithOtCard .h2", text: "2"
    assert_select "#mantencionesWithOtCard", text: /66[,.]7% del total/
    assert_select "#mantencionesProgrammedCard .h2", text: /66[,.]7%/
    assert_select "#mantencionesUnprogrammedCard .h2", text: /33[,.]3%/
    assert_select "#mantencionesSemanaChart", count: 0
    assert_select "#mantencionesDuracionChart", count: 0
    assert_select "div", text: "Duración total", count: 0
  end

  test "filtra los gráficos por especialidad, año y semana" do
    get graficos_mantenciones_url(especialidad: "mecanica", year: 2026, semana: 36)

    assert_response :success
    assert_select "select[name='especialidad'] option[selected][value='mecanica']"
    assert_select "select[name='year'] option[selected][value='2026']"
    assert_select "select[name='semana'] option[selected][value='36']", text: "Semana 36"
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

  test "busca mantenciones por texto y conserva el filtro de especialidad" do
    get mantenciones_url(especialidad: "mecanica", q: "motor")

    assert_response :success
    assert_select "input[name='q'][value='motor']"
    assert_select "#mantencion_#{mantenciones(:one).id}", count: 0
    assert_select "#mantencion_#{mantenciones(:two).id}", count: 1
    assert_select "input[name='especialidad'][value='mecanica'][type='hidden']"
  end

  test "busca mantenciones por número de OT" do
    get mantenciones_url(q: mantenciones(:one).numero_ot)

    assert_response :success
    assert_select "#mantencion_#{mantenciones(:one).id}", count: 1
    assert_select "#mantencion_#{mantenciones(:two).id}", count: 0
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

    assert_select "select[name='mantencion[planificacion]'] option", text: "Plan"
    assert_select "select[name='mantencion[planificacion]'] option", text: "Adicional"
    assert_select "select[name='mantencion[planificacion]'] option", text: "Reprogramado"
    assert_select "input[name='mantencion[planificacion]']", count: 0
    assert_select "select[name='mantencion[tipo_mantencion]'] option", text: "Preventiva"
    assert_select "select[name='mantencion[tipo_mantencion]'] option", text: "Correctivo Programado"
    assert_select "select[name='mantencion[tipo_mantencion]'] option", text: "Correctivo No programado"
    assert_select "select[name='mantencion[tipo_mantencion]'] option", text: "Reprogramar"
    assert_select "input[name='mantencion[tipo_mantencion]']", count: 0
    assert_select "label[for='mantencion_duracion']", text: "Duración del trabajo"
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
    assert_select "div.text-body-secondary.small", text: "Duración del trabajo"
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
  test "planning shortcuts filter independently of completion and preserve search" do
    record = Mantencion.create!(fecha: Date.new(2026, 9, 9), especialidad: "Eléctrico", actividad: "Revisión especial", planificacion: "Reprogramado", estado: 100)
    get reprogramado_mantenciones_url(q: "especial")
    assert_response :success
    assert_select "#mantencion_#{record.id}", count: 1
    assert_select "#mantencion_#{@mantencion.id}", count: 0
    assert_select "input[name='planificacion'][value='Reprogramado']"
    assert_select "a.active[href=?]", reprogramado_mantenciones_path
    assert_select "a.active[href=?]", mantenciones_path, count: 0
    get adicional_mantenciones_url
    assert_response :success
    assert_select "#mantencion_#{mantenciones(:two).id}", count: 1
    assert_select "#mantencion_#{record.id}", count: 0
    assert_select "#worksDropdown + ul li a", text: "Reprogramado"
    assert_select "#worksDropdown + ul li a", text: "Adicional"
  end

  test "weekly planning chart only displays the latest 38 weeks" do
    Mantencion.create!(fecha: Date.new(2026, 1, 1), semana: 1, especialidad: "Eléctrico", actividad: "Inicio de año", planificacion: "Plan")
    Mantencion.create!(fecha: Date.new(2026, 10, 28), semana: 44, especialidad: "Eléctrico", actividad: "Semana reciente", planificacion: "Reprogramado")
    get graficos_mantenciones_url(year: 2026)
    assert_response :success
    selector = "#mantencionesPlanificacionSemanalChartCard .chart-data li"
    assert_select selector, count: 38 * 3
    assert_select selector, text: "2026 · S6 · Plan: 0", count: 0
    assert_select selector, text: "2026 · S7 · Plan: 0"
    assert_select selector, text: "2026 · S44 · Reprogramado: 1"
  end

  test "weekly planning counts include zeros and distinguish years" do
    Mantencion.create!(fecha: Date.new(2025, 9, 3), semana: 36, especialidad: "Eléctrico", actividad: "Anterior", planificacion: "Reprogramado")
    Mantencion.create!(fecha: Date.new(2026, 9, 16), semana: 38, especialidad: "Eléctrico", actividad: "Nueva", planificacion: "Reprogramado")
    get graficos_mantenciones_url
    assert_response :success
    selector = "#mantencionesPlanificacionSemanalChartCard .chart-data li"
    assert_select selector, text: "2025 · S36 · Reprogramado: 1"
    assert_select selector, text: "2026 · S36 · Plan: 1"
    assert_select selector, text: "2026 · S36 · Adicional: 1"
    assert_select selector, text: "2026 · S36 · Reprogramado: 0"
    assert_select selector, text: "2026 · S37 · Plan: 0"
    assert_select selector, text: "2026 · S38 · Reprogramado: 1"
    get graficos_mantenciones_url(year: 2026, especialidad: "mecanica", semana: 36)
    assert_select selector, count: 3
    assert_select selector, text: "2026 · S36 · Plan: 0"
    assert_select selector, text: "2026 · S36 · Adicional: 1"
    get graficos_mantenciones_url(year: 2000)
    assert_response :success
    assert_select "canvas", count: 0
  end
end
