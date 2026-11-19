require "test_helper"

class OperationActivityMailerTest < ActionMailer::TestCase
  test "el correo incluye el detalle y enlaza a la misma semana" do
    OperationActivity.create!(fecha: "2026-05-24", area: "Calbuco", actividad: "Limpieza de la bodega", tipo: "Contingencia", estado: 80)
    email = OperationActivityMailer.weekly_report(recipients: [ "operaciones@example.com" ], week_of: Date.new(2026, 5, 21))

    assert_equal [ "operaciones@example.com" ], email.to
    assert_equal "Informe semanal de operaciones · Semana 21", email.subject
    [ email.html_part, email.text_part ].each do |part|
      body = part.body.decoded
      assert_includes body, "Limpieza de la bodega"
      assert_includes body, "80 %"
      assert_includes body, "/operaciones-ptm?semana=2026-05-18"
    end
  end
end
