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
    assert_equal ["destino@example.com"], email.to
    assert_includes email.subject, "##{work.id}"
    assert_equal 3, email.attachments.size
    assert_equal 3, email.attachments.map(&:filename).uniq.size
    email.attachments.each do |attachment|
      assert attachment.inline?
      assert_equal png.b, attachment.body.decoded.b
      assert_includes email.html_part.body.decoded, attachment.url
    end
    %w[Molienda MOL-02 Guantes Desgaste].each do |value|
      assert_includes email.html_part.body.decoded, value
      assert_includes email.text_part.body.decoded, value
    end
    assert_includes email.html_part.body.decoded, "Imágenes · Después"
  end
end
