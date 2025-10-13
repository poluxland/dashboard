require "test_helper"

class OtsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ot = ots(:one)
  end

  test "should get index" do
    get ots_url
    assert_response :success
  end

  test "should get new" do
    get new_ot_url
    assert_response :success
  end

  test "should create ot" do
    assert_difference("Ot.count") do
      post ots_url, params: { ot: { actividad_semanal: @ot.actividad_semanal, area: @ot.area, cantidad: @ot.cantidad, causa: @ot.causa, cc: @ot.cc, cod_rep: @ot.cod_rep, codigo: @ot.codigo, comentarios: @ot.comentarios, contratista: @ot.contratista, cotizacion: @ot.cotizacion, duracion_hr: @ot.duracion_hr, esp: @ot.esp, estado: @ot.estado, frecuencia: @ot.frecuencia, hh: @ot.hh, item: @ot.item, n_personas: @ot.n_personas, responsable: @ot.responsable, sem_ejec: @ot.sem_ejec, semana: @ot.semana, servicio: @ot.servicio, tipo_ot: @ot.tipo_ot, unitario: @ot.unitario } }
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
