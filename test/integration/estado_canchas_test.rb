require "test_helper"

class EstadoCanchasTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  teardown do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  test "the module uses Dashboard login" do
    get estado_canchas_path
    assert_redirected_to login_path
    get historial_estado_canchas_path
    assert_redirected_to login_path
  end

  test "records all materials, distinguishes zero from an empty field and allows edits" do
    sign_in_with_google
    get new_estado_cancha_path
    assert_response :success
    assert_select "input[type=number]", count: 14
    assert_select "label", text: "Ñilhue"
    assert_select "label", text: "Petcoke"

    assert_difference "EstadoCancha.count" do
      post estado_canchas_path, params: { estado_cancha: {
        quilimari: 0, ñilhue: 25, clinker_importado: 108, observaciones: "Cambio de acopio"
      } }
      assert_redirected_to estado_canchas_path
    end

    record = EstadoCancha.find_by!(observaciones: "Cambio de acopio")
    assert_equal 0, record.quilimari
    assert_equal 25, record.ñilhue
    assert_nil record.cachinales
    assert_nil record.pmm_id

    get estado_canchas_path
    assert_response :success
    assert_select "canvas", count: 2
    assert_select "option", text: "Clínker importado"
    assert_select "td", text: "108 %"

    get edit_estado_cancha_path(record)
    assert_response :success
    patch estado_cancha_path(record), params: { estado_cancha: { clinker_importado: "94" } }
    assert_redirected_to record
    follow_redirect!
    assert_select "dd", text: "94 %"
  end

  test "the full history filters dates in Chile and retains the JSON endpoint" do
    sign_in_with_google
    chile = EstadoCancha::CHILE
    current = EstadoCancha.create!(clinker_importado: 25, observaciones: "Dentro", created_at: chile.local(2026, 11, 18, 23, 59))
    EstadoCancha.create!(observaciones: "Siguiente día", created_at: chile.local(2026, 11, 19))

    get historial_estado_canchas_path, params: { desde: "2026-11-18", hasta: "2026-11-18" }
    assert_response :success
    assert_select "td", text: "Dentro"
    assert_select "td", text: "Siguiente día", count: 0

    get estado_cancha_path(current, format: :json)
    assert_response :success
    assert_equal 25, response.parsed_body.fetch("clinker_importado")
    assert_equal 25, current.reload.clinker_importado
  end

  test "a new record emails its occupancy chart to the configured recipients" do
    key = "ESTADO_CANCHAS_REPORT_RECIPIENTS"
    previous = ENV[key]
    recipients = %w[turno@example.com operaciones@example.com]
    ENV[key] = recipients.join(",")
    sign_in_with_google

    emails = capture_emails do
      post estado_canchas_path, params: { estado_cancha: {
        quilimari: 0, ñilhue: 25, clinker_importado: 108, observaciones: "Cambio de acopio\nRevisión <pendiente>"
      } }
      assert_redirected_to estado_canchas_path
    end

    email = emails.sole
    assert_equal recipients, email.to
    assert_match(/\AEstado de canchas - /, email.subject)
    html = Nokogiri::HTML(email.html_part.decoded)
    rows = html.css("th[scope=row]").index_by(&:text)
    assert_equal EstadoCancha::MATERIALS.size, rows.size
    assert_equal "0 %", rows.fetch("Quilimari").parent.css("td").last.text.strip
    assert_equal "Sin dato", rows.fetch("Cachinales").parent.css("td").last.text.strip
    assert rows.fetch("Ñilhue").parent.at_css('table[width="25%"]')
    imported = rows.fetch("Clínker importado").parent
    assert_equal "108 %", imported.css("td").last.text.strip
    assert imported.at_css('table[width="100%"] table[width="100%"]')
    assert_includes email.html_part.decoded, "Cambio de acopio<br>Revisión &lt;pendiente&gt;"
    assert_includes email.text_part.decoded, "Cachinales: Sin dato"

    record = EstadoCancha.recent_first.first
    assert_no_enqueued_emails do
      patch estado_cancha_path(record), params: { estado_cancha: { clinker_importado: 94 } }
      assert_redirected_to record
    end
  ensure
    ENV[key] = previous
  end
end
