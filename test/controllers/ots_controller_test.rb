require "test_helper"

class OtsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ot = ots(:one)
  end

  test "should get index" do
    get ots_url
    assert_response :success
    assert_select "thead th:nth-child(2)", text: "Año"
    assert_select "tbody tr td:nth-child(2)", text: @ot.created_at.year.to_s
    assert_select "a[href='#{ots_path(current_year: 1)}']", text: "OTs año"
  end

  test "current year index only shows ots created this year" do
    previous_year_ot = @ot
    previous_year_ot.update_column(:created_at, 1.year.ago)
    current_year_ot = ots(:two)

    get ots_url(current_year: 1)

    assert_response :success
    assert_select "tbody", text: /#{current_year_ot.ot_asignada}/
    assert_select "tbody", { text: /#{previous_year_ot.ot_asignada}/, count: 0 }
  end

  test "should get new" do
    get new_ot_url
    assert_response :success
  end

  test "should create ot" do
    new_ot_asignada = (Ot.maximum(:ot_asignada) || 0) + 1  # garantiza unicidad

    assert_difference("Ot.count", +1) do
      post ots_url, params: {
        ot: {
          ot_asignada: new_ot_asignada  # <-- mínimo requerido por tu validación
          # puedes agregar opcionalmente:
          # estado: 80, tipo_ot: "F"
        }
      }
    end

    assert_redirected_to ot_url(Ot.last)
  end


  test "should show ot" do
    get ot_url(@ot)
    assert_response :success
  end

  test "should get edit" do
    get edit_ot_url(@ot)
    assert_response :success
  end

  test "should update ot" do
    patch ot_url(@ot), params: { ot: { actividad_semanal: @ot.actividad_semanal, area: @ot.area, cantidad: @ot.cantidad, causa: @ot.causa, cc: @ot.cc, cod_rep: @ot.cod_rep, codigo: @ot.codigo, comentarios: @ot.comentarios, contratista: @ot.contratista, cotizacion: @ot.cotizacion, duracion_hr: @ot.duracion_hr, esp: @ot.esp, estado: @ot.estado, frecuencia: @ot.frecuencia, hh: @ot.hh, item: @ot.item, n_personas: @ot.n_personas, responsable: @ot.responsable, sem_ejec: @ot.sem_ejec, semana: @ot.semana, servicio: @ot.servicio, tipo_ot: @ot.tipo_ot, unitario: @ot.unitario } }
    assert_redirected_to ot_url(@ot)
  end

  test "should destroy ot" do
    assert_difference("Ot.count", -1) do
      delete ot_url(@ot)
    end

    assert_redirected_to ots_url
  end
end
