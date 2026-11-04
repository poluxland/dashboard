require "test_helper"

class WorkMailerTest < ActionMailer::TestCase
  test "includes report fields and all photo groups as embedded attachments" do
    work = works(:one)
    work.update!(area: "Molienda", tag: "MOL-02", repuestos: "Dos rodamientos", epp: "Guantes", hallazgos: "Desgaste", observaciones: "Verificar vibración")
    png = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aD1sAAAAASUVORK5CYII=")
    %i[fotos fotos_antes fotos_despues].each do |field|
      work.public_send(field).attach(io: StringIO.new(png), filename: "foto.png", content_type: "image/png")
    end

    email = WorkMailer.technical_report(work, recipient: "destino@example.com")
    assert_equal [ "destino@example.com" ], email.to
    assert_includes email.subject, "##{work.id}"
    assert_equal 4, email.attachments.size
    assert_equal 4, email.attachments.map(&:filename).uniq.size
    assert_equal File.binread(Rails.root.join("app/assets/images/impromaq-logo.png")), email.attachments["impromaq-logo.png"].body.decoded.b
    email.attachments.each do |attachment|
      assert attachment.inline?
      assert_equal png.b, attachment.body.decoded.b unless attachment.filename == "impromaq-logo.png"
      assert_includes email.html_part.body.decoded, attachment.url
    end
    %w[Molienda MOL-02 Guantes Desgaste].each do |value|
      assert_includes email.html_part.body.decoded, value
      assert_includes email.text_part.body.decoded, value
    end
    assert_includes email.html_part.body.decoded, "Imágenes · Después"
    html = email.html_part.body.decoded
    assert_operator html.index("Imágenes · Antes"), :>, html.index("Imágenes · Adicionales")
    assert_operator html.index("Imágenes · Después"), :>, html.index("Imágenes · Antes")
    report_url = "http://example.com/informes/compartidos/#{work.report_token}"
    assert_includes email.text_part.body.decoded, report_url
    document = Nokogiri::HTML(email.html_part.body.decoded)
    assert_equal 3, document.css("a[href='#{report_url}'] img[width='160']").size
    assert document.at_css("a[href='#{report_url}']")
  end
  test "email hides empty fields, photo groups and unanswered inspection items" do
    work = Work.create!(fecha: nil)
    inspection = work.inspections.create!(template_key: "seguridad")
    inspection.items.first.update!(observations: "Pendiente revisar documento")
    email = WorkMailer.technical_report(work, recipient: "destino@example.com")
    [ email.html_part.body.decoded, email.text_part.body.decoded ].each do |body|
      assert_not_includes body, "Sin registrar"
      assert_not_includes body, "Sin título"
      assert_not_includes body, "Sin responder"
      assert_not_includes body, "Personal con EPP"
      assert_not_includes body, "Imágenes · Antes"
      assert_not_includes body, "FOTOGRAFÍAS INCLUIDAS"
      assert_includes body, "Pendiente revisar documento"
      assert_includes body, "0/7 revisados"
    end
  end
end
