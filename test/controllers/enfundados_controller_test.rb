require "test_helper"

class EnfundadosControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_with_google
    @enfundado = enfundados(:one)
  end

  test "should get index" do
    get enfundados_url
    assert_response :success
    assert_select "a[href='#{inventario_films_enfundados_path}']", text: "Inventario"
  end

  test "should get new" do
    get new_enfundado_url
    assert_response :success
  end

  test "should get inventario films" do
    travel_to EnfundadosController::FECHA_STOCK_FISICO_FILMS do
      EntregaFilm.create!(fecha: Date.current, rollos_entregados: 8)
      Enfundado.create!(
        operador: "Operador prueba",
        fecha: Date.current,
        turno: Enfundado::TURNOS.first,
        numero_rollos_films_cambiados_manual: 2,
        numero_rollos_films_cambiados_automatica: 1,
        numero_rollos_films_tapa: 4
      )

      get inventario_films_enfundados_url

      assert_response :success
      assert_select ".rep-inventory-table tbody tr", count: 3
      assert_select ".rep-inventory-table thead th", count: 17
      assert_select "[data-inventario-entregados]", text: /8/
      assert_select "[data-inventario-usados]", text: /7/
      assert_select "[data-inventario-fecha='#{Date.current.iso8601}']", text: /2/
    end
  end

  test "reporte does not show films inventory" do
    get reporte_enfundados_url

    assert_response :success
    assert_select ".rep-inventory-table", count: 0
  end

  test "should create enfundado" do
    assert_difference("Enfundado.count") do
      post enfundados_url, params: { enfundado: { especial_plastificado_completo_doble_films_automatica: @enfundado.especial_plastificado_completo_doble_films_automatica, especial_plastificado_completo_doble_films_manual: @enfundado.especial_plastificado_completo_doble_films_manual, especial_plastificado_zuncho_reforzado_automatica: @enfundado.especial_plastificado_zuncho_reforzado_automatica, especial_plastificado_zuncho_reforzado_manual: @enfundado.especial_plastificado_zuncho_reforzado_manual, especial_plastificados_3_vueltas_automatica: @enfundado.especial_plastificados_3_vueltas_automatica, especial_plastificados_3_vueltas_manual: @enfundado.especial_plastificados_3_vueltas_manual, especial_plastificados_completo_automatica: @enfundado.especial_plastificados_completo_automatica, especial_plastificados_completo_manual: @enfundado.especial_plastificados_completo_manual, especial_plastificados_lados_automatica: @enfundado.especial_plastificados_lados_automatica, especial_plastificados_lados_manual: @enfundado.especial_plastificados_lados_manual, especial_soluble_plastificados_completo_automatica: @enfundado.especial_soluble_plastificados_completo_automatica, especial_soluble_plastificados_completo_manual: @enfundado.especial_soluble_plastificados_completo_manual, extra_plastificados_completo_doble_films_automatica: @enfundado.extra_plastificados_completo_doble_films_automatica, extra_plastificados_completo_doble_films_manual: @enfundado.extra_plastificados_completo_doble_films_manual, extra_plastificados_completo_doble_films_zuncho_automatica: @enfundado.extra_plastificados_completo_doble_films_zuncho_automatica, extra_plastificados_completo_doble_films_zuncho_manual: @enfundado.extra_plastificados_completo_doble_films_zuncho_manual, extra_plastificados_lados_automatica: @enfundado.extra_plastificados_lados_automatica, extra_plastificados_lados_manual: @enfundado.extra_plastificados_lados_manual, extra_soluble_plastificados_completo_automatica: @enfundado.extra_soluble_plastificados_completo_automatica, extra_soluble_plastificados_completo_manual: @enfundado.extra_soluble_plastificados_completo_manual, fecha: @enfundado.fecha + 1.day, numero_pallet_enfundado_automatica: @enfundado.numero_pallet_enfundado_automatica, numero_pallet_enfundado_manual: @enfundado.numero_pallet_enfundado_manual, numero_rollos_films_cambiados_automatica: @enfundado.numero_rollos_films_cambiados_automatica, numero_rollos_films_cambiados_manual: @enfundado.numero_rollos_films_cambiados_manual, numero_rollos_films_tapa: @enfundado.numero_rollos_films_tapa, operador: @enfundado.operador, turno: @enfundado.turno } }
    end

    assert_redirected_to enfundados_url
  end

  test "should show enfundado" do
    get enfundado_url(@enfundado)
    assert_response :success
  end

  test "should get edit" do
    get edit_enfundado_url(@enfundado)
    assert_response :success
  end

  test "should update enfundado" do
    patch enfundado_url(@enfundado), params: { enfundado: { especial_plastificado_completo_doble_films_automatica: @enfundado.especial_plastificado_completo_doble_films_automatica, especial_plastificado_completo_doble_films_manual: @enfundado.especial_plastificado_completo_doble_films_manual, especial_plastificado_zuncho_reforzado_automatica: @enfundado.especial_plastificado_zuncho_reforzado_automatica, especial_plastificado_zuncho_reforzado_manual: @enfundado.especial_plastificado_zuncho_reforzado_manual, especial_plastificados_3_vueltas_automatica: @enfundado.especial_plastificados_3_vueltas_automatica, especial_plastificados_3_vueltas_manual: @enfundado.especial_plastificados_3_vueltas_manual, especial_plastificados_completo_automatica: @enfundado.especial_plastificados_completo_automatica, especial_plastificados_completo_manual: @enfundado.especial_plastificados_completo_manual, especial_plastificados_lados_automatica: @enfundado.especial_plastificados_lados_automatica, especial_plastificados_lados_manual: @enfundado.especial_plastificados_lados_manual, especial_soluble_plastificados_completo_automatica: @enfundado.especial_soluble_plastificados_completo_automatica, especial_soluble_plastificados_completo_manual: @enfundado.especial_soluble_plastificados_completo_manual, extra_plastificados_completo_doble_films_automatica: @enfundado.extra_plastificados_completo_doble_films_automatica, extra_plastificados_completo_doble_films_manual: @enfundado.extra_plastificados_completo_doble_films_manual, extra_plastificados_completo_doble_films_zuncho_automatica: @enfundado.extra_plastificados_completo_doble_films_zuncho_automatica, extra_plastificados_completo_doble_films_zuncho_manual: @enfundado.extra_plastificados_completo_doble_films_zuncho_manual, extra_plastificados_lados_automatica: @enfundado.extra_plastificados_lados_automatica, extra_plastificados_lados_manual: @enfundado.extra_plastificados_lados_manual, extra_soluble_plastificados_completo_automatica: @enfundado.extra_soluble_plastificados_completo_automatica, extra_soluble_plastificados_completo_manual: @enfundado.extra_soluble_plastificados_completo_manual, fecha: @enfundado.fecha, numero_pallet_enfundado_automatica: @enfundado.numero_pallet_enfundado_automatica, numero_pallet_enfundado_manual: @enfundado.numero_pallet_enfundado_manual, numero_rollos_films_cambiados_automatica: @enfundado.numero_rollos_films_cambiados_automatica, numero_rollos_films_cambiados_manual: @enfundado.numero_rollos_films_cambiados_manual, operador: @enfundado.operador, turno: @enfundado.turno } }
    assert_redirected_to enfundados_url
  end

  test "should destroy enfundado" do
    assert_difference("Enfundado.count", -1) do
      delete enfundado_url(@enfundado)
    end

    assert_redirected_to enfundados_url
  end
end
