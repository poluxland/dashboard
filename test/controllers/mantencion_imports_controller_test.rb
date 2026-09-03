require "test_helper"

class MantencionImportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_with_google(email: "jose.jerez@msindustrial.cl")
  end

  test "muestra el formulario al usuario autorizado" do
    get new_mantencion_import_url

    assert_response :success
    assert_select "h1", text: "Importar mantenciones"
    assert_select "input[type='file'][name='archivo']", count: 1
  end

  test "importa el archivo y muestra el resultado" do
    row = [
      36, Date.new(2026, 9, 2), "Eléctrico", "P416", "WT01", "Preventivo",
      "Inspección desde controlador", "Plan", 1, 55990100, 2, "Finalizada"
    ]

    with_mantencion_xlsx([ row ]) do |upload|
      assert_difference("Mantencion.count", 1) do
        post mantencion_import_url, params: { archivo: upload, confirmar: "1" }
      end
    end

    assert_response :success
    assert_select "h2", text: "Resultado de la importación"
    assert_select ".text-success", text: "1"
  end

  test "rechaza la importación para otro usuario" do
    delete logout_url
    sign_in_with_google(email: "usuario@msindustrial.cl", uid: "sin-importacion")

    assert_no_difference("Mantencion.count") do
      post mantencion_import_url, params: { confirmar: "1" }
    end

    assert_redirected_to root_url
  end
end
