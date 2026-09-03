require "test_helper"

class EstadoEquiposControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_with_google(email: "jose.jerez@msindustrial.cl")
    @estado_equipo = estado_equipos(:one)
  end

  test "rechaza usuarios sin acceso a Demo" do
    delete logout_url
    sign_in_with_google(email: "usuario@msindustrial.cl", uid: "sin-demo")

    get estado_equipos_url

    assert_redirected_to root_url
  end

  test "should get index" do
    get estado_equipos_url
    assert_response :success
  end

  test "should get new" do
    get new_estado_equipo_url
    assert_response :success
  end

  test "should create estado_equipo" do
    assert_difference("EstadoEquipo.count") do
      post estado_equipos_url, params: { estado_equipo: { comentarios: @estado_equipo.comentarios, equipo: @estado_equipo.equipo, equipo_principal: @estado_equipo.equipo_principal, estado_capachos: @estado_equipo.estado_capachos, estado_cinta: @estado_equipo.estado_cinta, estado_estructura: @estado_equipo.estado_estructura, estado_filtro: @estado_equipo.estado_filtro, estado_limpieza: @estado_equipo.estado_limpieza, estado_lubricacion: @estado_equipo.estado_lubricacion, estado_motor: @estado_equipo.estado_motor, estado_polines: @estado_equipo.estado_polines, estado_ruedas: @estado_equipo.estado_ruedas, estado_sistema_aire: @estado_equipo.estado_sistema_aire } }
    end

    assert_redirected_to estado_equipo_url(EstadoEquipo.last)
  end

  test "should show estado_equipo" do
    get estado_equipo_url(@estado_equipo)
    assert_response :success
  end

  test "should get edit" do
    get edit_estado_equipo_url(@estado_equipo)
    assert_response :success
  end

  test "should update estado_equipo" do
    patch estado_equipo_url(@estado_equipo), params: { estado_equipo: { comentarios: @estado_equipo.comentarios, equipo: @estado_equipo.equipo, equipo_principal: @estado_equipo.equipo_principal, estado_capachos: @estado_equipo.estado_capachos, estado_cinta: @estado_equipo.estado_cinta, estado_estructura: @estado_equipo.estado_estructura, estado_filtro: @estado_equipo.estado_filtro, estado_limpieza: @estado_equipo.estado_limpieza, estado_lubricacion: @estado_equipo.estado_lubricacion, estado_motor: @estado_equipo.estado_motor, estado_polines: @estado_equipo.estado_polines, estado_ruedas: @estado_equipo.estado_ruedas, estado_sistema_aire: @estado_equipo.estado_sistema_aire } }
    assert_redirected_to estado_equipo_url(@estado_equipo)
  end

  test "should destroy estado_equipo" do
    assert_difference("EstadoEquipo.count", -1) do
      delete estado_equipo_url(@estado_equipo)
    end

    assert_redirected_to estado_equipos_url
  end
end
