require "test_helper"

class EntregaFilmsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @entrega_film = entrega_films(:one)
  end

  test "should get index" do
    get entrega_films_url
    assert_response :success
  end

  test "should get new" do
    get new_entrega_film_url
    assert_response :success
  end

  test "should create entrega_film" do
    assert_difference("EntregaFilm.count") do
      post entrega_films_url, params: { entrega_film: { fecha: @entrega_film.fecha, observaciones: @entrega_film.observaciones, operador_bodega: @entrega_film.operador_bodega, rollos_entregados: @entrega_film.rollos_entregados } }
    end

    assert_redirected_to entrega_film_url(EntregaFilm.last)
  end

  test "should show entrega_film" do
    get entrega_film_url(@entrega_film)
    assert_response :success
  end

  test "should get edit" do
    get edit_entrega_film_url(@entrega_film)
    assert_response :success
  end

  test "should update entrega_film" do
    patch entrega_film_url(@entrega_film), params: { entrega_film: { fecha: @entrega_film.fecha, observaciones: @entrega_film.observaciones, operador_bodega: @entrega_film.operador_bodega, rollos_entregados: @entrega_film.rollos_entregados } }
    assert_redirected_to entrega_film_url(@entrega_film)
  end

  test "should destroy entrega_film" do
    assert_difference("EntregaFilm.count", -1) do
      delete entrega_film_url(@entrega_film)
    end

    assert_redirected_to entrega_films_url
  end
end
