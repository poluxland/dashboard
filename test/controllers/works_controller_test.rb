require "test_helper"

class WorksControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_with_google
    @work = works(:one)
  end

  test "should get index" do
    get works_url
    assert_response :success
  end

  test "should get new" do
    get new_work_url
    assert_response :success
  end

  test "should create work" do
    assert_difference("Work.count") do
      post works_url, params: { work: { descripcion: @work.descripcion, fecha: @work.fecha, hora_inicio: @work.hora_inicio, hora_termino: @work.hora_termino, nombre: @work.nombre, numero_cotizacion: @work.numero_cotizacion, personal: @work.personal, planta: @work.planta, seguridad: @work.seguridad, solicita: @work.solicita, supervisor: @work.supervisor } }
    end

    assert_redirected_to work_url(Work.last)
  end

  test "should show work" do
    get work_url(@work)
    assert_response :success
  end

  test "should get edit" do
    get edit_work_url(@work)
    assert_response :success
  end

  test "should update work" do
    patch work_url(@work), params: { work: { descripcion: @work.descripcion, fecha: @work.fecha, hora_inicio: @work.hora_inicio, hora_termino: @work.hora_termino, nombre: @work.nombre, numero_cotizacion: @work.numero_cotizacion, personal: @work.personal, planta: @work.planta, seguridad: @work.seguridad, solicita: @work.solicita, supervisor: @work.supervisor } }
    assert_redirected_to work_url(@work)
  end

  test "should destroy work" do
    assert_difference("Work.count", -1) do
      delete work_url(@work)
    end

    assert_redirected_to works_url
  end
  test "creates and displays a technical report with separate before and after evidence" do
    fields = {
      area: "Molienda", tag: "MOL-02", fecha: "2026-09-28",
      repuestos: "2 rodamientos", epp: "Guantes y lentes",
      hallazgos: "Rodamiento desgastado", observaciones: "Verificar vibración",
      fotos_antes: [image_blob("antes.png").signed_id],
      fotos_despues: [image_blob("despues.png").signed_id]
    }
    assert_difference("Work.count") do
      post works_url, params: { work: fields }
    end
    report = Work.order(:id).last
    assert_redirected_to work_url(report)
    fields.except(:fecha, :fotos_antes, :fotos_despues).each do |field, value|
      assert_equal value, report.public_send(field)
    end
    assert_equal ["antes.png"], report.fotos_antes.map { |photo| photo.filename.to_s }
    assert_equal ["despues.png"], report.fotos_despues.map { |photo| photo.filename.to_s }
    get work_url(report)
    assert_response :success
    assert_select "h1", "Informe técnico de mantenimiento · Impromaq"
    assert_select "img[alt='Imágenes antes: antes.png']"
    assert_select "img[alt='Imágenes después: despues.png']"
    assert_match "Rodamiento desgastado", response.body
    get works_url
    assert_response :success
    assert_select "td", "MOL-02"
  end

  test "editing preserves evidence and adds new photos without replacing old photos" do
    %i[fotos fotos_antes fotos_despues].each do |field|
      @work.public_send(field).attach(image_blob("#{field}-original.png"))
    end
    patch work_url(@work), params: { work: {
      observaciones: "Prueba satisfactoria", fotos: [""], fotos_despues: [""],
      fotos_antes: ["", image_blob("otra.png").signed_id]
    } }
    assert_redirected_to work_url(@work)
    @work.reload
    assert_equal "Prueba satisfactoria", @work.observaciones
    assert_equal 1, @work.fotos.count
    assert_equal 1, @work.fotos_despues.count
    assert_equal ["fotos_antes-original.png", "otra.png"], @work.fotos_antes.map { |photo| photo.filename.to_s }
  end

  test "rejects non image evidence without changing saved report" do
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("plain text"), filename: "invalid.txt", content_type: "text/plain")
    patch work_url(@work), params: { work: { fotos_despues: [blob.signed_id] } }
    assert_response :unprocessable_entity
    assert_not @work.reload.fotos_despues.attached?
  end

  test "email form opens without sending and accepts one recipient" do
    assert_no_difference("ActionMailer::Base.deliveries.size") do
      get email_work_url(@work)
    end
    assert_response :success
    assert_select "input[type=email][name=recipient]"
    assert_difference("ActionMailer::Base.deliveries.size", 1) do
      post send_email_work_url(@work), params: { recipient: " destino@example.com " }
    end
    assert_redirected_to work_url(@work)
    assert_equal ["destino@example.com"], ActionMailer::Base.deliveries.last.to
  end

  test "does not send to invalid or multiple recipients" do
    ["", "invalid", "one@example.com,two@example.com", "one@example.com\r\nBcc: other@example.com"].each do |recipient|
      assert_no_difference("ActionMailer::Base.deliveries.size") do
        post send_email_work_url(@work), params: { recipient: recipient }
      end
      assert_response :unprocessable_entity
    end
  end

  test "email requires authentication" do
    delete logout_url
    assert_no_difference("ActionMailer::Base.deliveries.size") do
      post send_email_work_url(@work), params: { recipient: "destino@example.com" }
    end
    assert_redirected_to login_path
  end

  test "reports oversized evidence without sending a partial report" do
    blob = image_blob("large.png")
    @work.fotos.attach(blob)
    blob.update!(byte_size: 16.megabytes)
    assert_no_difference("ActionMailer::Base.deliveries.size") do
      post send_email_work_url(@work), params: { recipient: "destino@example.com" }
    end
    assert_response :unprocessable_entity
    assert_match "superan los 15 MB", response.body
  end

  test "missing photos produce an error instead of a success confirmation" do
    blob = image_blob("missing.png")
    @work.fotos.attach(blob)
    blob.service.delete(blob.key)
    assert_no_difference("ActionMailer::Base.deliveries.size") do
      post send_email_work_url(@work), params: { recipient: "destino@example.com" }
    end
    assert_response :service_unavailable
    assert_match "No se pudo confirmar", response.body
  end

  private

  def image_blob(filename)
    png = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aD1sAAAAASUVORK5CYII=")
    ActiveStorage::Blob.create_and_upload!(io: StringIO.new(png), filename: filename, content_type: "image/png")
  end

end
