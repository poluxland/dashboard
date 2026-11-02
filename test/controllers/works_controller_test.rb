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
      fotos_antes: [ image_blob("antes.png").signed_id ],
      fotos_despues: [ image_blob("despues.png").signed_id ]
    }
    assert_difference("Work.count") do
      post works_url, params: { work: fields }
    end
    report = Work.order(:id).last
    assert_redirected_to work_url(report)
    fields.except(:fecha, :fotos_antes, :fotos_despues).each do |field, value|
      assert_equal value, report.public_send(field)
    end
    assert_equal [ "antes.png" ], report.fotos_antes.map { |photo| photo.filename.to_s }
    assert_equal [ "despues.png" ], report.fotos_despues.map { |photo| photo.filename.to_s }
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
      observaciones: "Prueba satisfactoria", fotos: [ "" ], fotos_despues: [ "" ],
      fotos_antes: [ "", image_blob("otra.png").signed_id ]
    } }
    assert_redirected_to work_url(@work)
    @work.reload
    assert_equal "Prueba satisfactoria", @work.observaciones
    assert_equal 1, @work.fotos.count
    assert_equal 1, @work.fotos_despues.count
    assert_equal [ "fotos_antes-original.png", "otra.png" ], @work.fotos_antes.map { |photo| photo.filename.to_s }
  end

  test "rejects non image evidence without changing saved report" do
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("plain text"), filename: "invalid.txt", content_type: "text/plain")
    patch work_url(@work), params: { work: { fotos_despues: [ blob.signed_id ] } }
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
    assert_equal [ "destino@example.com" ], ActionMailer::Base.deliveries.last.to
  end

  test "does not send to invalid or multiple recipients" do
    [ "", "invalid", "one@example.com,two@example.com", "one@example.com\r\nBcc: other@example.com" ].each do |recipient|
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

  test "creates one partial inspection and preserves item evidence when editing" do
    post works_url, params: { work: { planta: "Prueba", inspections_attributes: {
      "0" => { template_key: "seguridad", enabled: "1", items_attributes: {
        "0" => { position: "0", answer: "no", observations: "Falta AST", fotos_uploads: [ image_blob("ast.png").signed_id ] }
      } },
      "1" => { template_key: "molino1", enabled: "0" },
      "2" => { template_key: "molino2", enabled: "0" }
    } } }
    report = Work.order(:id).last
    assert_redirected_to work_url(report)
    assert_equal 1, report.inspections.count
    inspection = report.inspections.find_by!(template_key: "seguridad")
    assert_equal 7, inspection.items.count
    item = inspection.items.first
    assert_equal "no", item.answer
    assert_equal "Falta AST", item.observations
    assert_equal 1, item.fotos.count
    patch work_url(report), params: { work: { inspections_attributes: {
      "0" => { id: inspection.id, template_key: "seguridad", enabled: "1", items_attributes: {
        "0" => { id: item.id, position: "0", answer: "yes", fotos_uploads: [ "", image_blob("ast-nuevo.png").signed_id ] }
      } }
    } } }
    assert_redirected_to work_url(report)
    assert_equal "yes", item.reload.answer
    assert_equal 2, item.fotos.count
    get work_url(report)
    assert_select "h2", "Inspección de Seguridad"
    assert_match "Incompleta", response.body
    get work_url(report, format: :json)
    assert_equal 1, response.parsed_body["inspections"].size
    patch work_url(report), params: { work: { inspections_attributes: {
      "0" => { id: inspection.id, enabled: "0" }
    } } }
    assert_redirected_to work_url(report)
    assert_not inspection.reload.enabled?
    assert_equal 2, item.reload.fotos.count
    assert_equal "yes", item.answer
  end

  test "rejects multiple selected inspections without creating a report" do
    assert_no_difference("Work.count") do
      post works_url, params: { work: { inspections_attributes: {
        "0" => { template_key: "seguridad", enabled: "1" },
        "1" => { template_key: "molino1", enabled: "1" }
      } } }
    end
    assert_response :unprocessable_entity
    assert_includes response.body, "Solo puedes seleccionar una inspección por trabajo."
  end

  test "dropdown switches inspections and restores saved answers when switching back" do
    inspection = @work.inspections.create!(template_key: "seguridad")
    inspection.items.first.update!(answer: "no", observations: "AST pendiente")
    patch work_url(@work), params: { work: { inspection_type: "molino1" } }
    assert_redirected_to work_url(@work)
    assert_equal [ "molino1" ], @work.reload.selected_inspections.map(&:template_key)
    assert_equal "no", inspection.items.first.reload.answer
    patch work_url(@work), params: { work: { inspection_type: "seguridad" } }
    assert_redirected_to work_url(@work)
    assert_equal [ "seguridad" ], @work.reload.selected_inspections.map(&:template_key)
    assert_equal "AST pendiente", inspection.items.first.reload.observations
    get edit_work_url(@work)
    assert_select "select[name='work[inspection_type]'] option[selected][value=seguridad]", count: 1
    assert_select "input[type=checkbox][data-inspection-toggle]", count: 0
    patch work_url(@work), params: { work: { inspection_type: "" } }
    assert_redirected_to work_url(@work)
    assert_empty @work.reload.selected_inspections
  end

  test "filters inspection reports and rejects invalid nested answers" do
    inspection = @work.inspections.create!(template_key: "seguridad")
    get works_url, params: { inspection_type: "seguridad", inspection_state: "Sin iniciar" }
    assert_select "tr#work_#{@work.id}", count: 1
    get works_url, params: { inspection_type: "molino1" }
    assert_select "tr#work_#{@work.id}", count: 0
    patch work_url(@work), params: { work: { inspections_attributes: {
      "0" => { id: inspection.id, items_attributes: {
        "0" => { id: inspection.items.first.id, answer: "invalid" }
      } }
    } } }
    assert_response :unprocessable_entity
    assert_nil inspection.items.first.reload.answer
  end

  test "email includes inspection answers and item photos" do
    inspection = @work.inspections.create!(template_key: "seguridad")
    inspection.items.first.update!(answer: "no", observations: "AST pendiente", fotos_uploads: [ image_blob("ast.png").signed_id ])
    post send_email_work_url(@work), params: { recipient: "destino@example.com" }
    assert_redirected_to work_url(@work)
    email = ActionMailer::Base.deliveries.last
    assert_equal 2, email.attachments.size
    assert_includes email.html_part.body.decoded, "AST pendiente"
    assert_includes email.text_part.body.decoded, "No cumple"
  end

  private

  def image_blob(filename)
    png = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aD1sAAAAASUVORK5CYII=")
    ActiveStorage::Blob.create_and_upload!(io: StringIO.new(png), filename: filename, content_type: "image/png")
  end
end
