require "test_helper"

class PublicWorkReportsControllerTest < ActionDispatch::IntegrationTest
  test "signed link displays only its report and inspection without login or controls" do
    work = works(:one)
    work.update!(nombre: "Reporte compartido", descripcion: "Detalle del trabajo")
    works(:two).update!(nombre: "Reporte privado distinto")
    inspection = work.inspections.create!(template_key: "seguridad")
    inspection.items.first.update!(answer: "no", observations: "Revisar AST")
    get public_work_report_url(token: work.report_token), params: { id: works(:two).id }
    assert_response :success
    assert_includes response.body, "Reporte compartido"
    assert_includes response.body, "Revisar AST"
    assert_not_includes response.body, "Reporte privado distinto"
    assert_select "form, nav", count: 0
    assert_select "a[href^='/works']", count: 0
    assert_select "[data-turbo-method]", count: 0
    assert_equal "no-store", response.headers["Cache-Control"]
    assert_equal "no-referrer", response.headers["Referrer-Policy"]
    assert_includes response.headers["X-Robots-Tag"], "noindex"
  end

  test "invalid tokens and tokens for other purposes do not expose reports" do
    [ works(:one).id.to_s, "invalid", works(:one).signed_id(purpose: :other), works(:one).report_token + "x" ].each do |token|
      get public_work_report_url(token: token)
      assert_response :not_found
    end
  end

  test "photos in the shared report can be viewed without signing in" do
    work = works(:one)
    work.fotos_antes.attach(io: File.open(Rails.root.join("app/assets/images/impromaq-logo.png")), filename: "evidencia.png", content_type: "image/png")
    get public_work_report_url(token: work.report_token)
    assert_response :success
    photo_url = Nokogiri::HTML(response.body).at_css("img[alt='Imágenes antes: evidencia.png']")["src"]
    get photo_url
    assert_response :redirect
    assert_not_includes response.location, "/login"
    follow_redirect!
    assert_response :success
    assert_equal "image/png", response.media_type
  end

  test "sharing does not authorize private routes or editing" do
    work = works(:one)
    token = work.report_token
    get works_url, params: { token: token }
    assert_redirected_to login_path
    get edit_work_url(work), params: { token: token }
    assert_redirected_to login_path
    original = work.nombre
    patch work_url(work), params: { token: token, work: { nombre: "Unauthorized" } }
    assert_redirected_to login_path
    assert_equal original, work.reload.nombre
    get public_work_report_url(token: token, format: :json)
    assert_response :not_acceptable
  end

  test "deleted reports cannot be opened through old links" do
    work = works(:one)
    token = work.report_token
    work.destroy!
    get public_work_report_url(token: token)
    assert_response :not_found
  end
end
