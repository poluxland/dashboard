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

  test "el HTML muestra barras por desglose y el avance al final de cada actividad" do
    [ 100, 50, 0 ].each do |state|
      OperationActivity.create!(
        fecha: "2026-05-24", area: "Calbuco", actividad: "Actividad #{state}\nSector en planilla: Domo Calbuco",
        tipo: "Programada", estado: state
      )
    end
    email = OperationActivityMailer.weekly_report(recipients: [ "operaciones@example.com" ], week_of: Date.new(2026, 5, 21))
    html = Nokogiri::HTML(email.html_part.body.decoded)

    assert_equal [ "Estado de ejecución", "Tipo de actividad", "Actividades por área", "Actividades de la semana" ], html.css("h2").map(&:text)
    assert_equal 3, html.css('td[height="12"][width="33.3%"][bgcolor]').size
    assert_equal 2, html.css('td[height="12"][width="100.0%"][bgcolor]').size

    badges = html.css(".operations-email-advance span")
    assert_equal %w[100% 50% 0%], badges.map(&:text)
    %w[#166534 #92400e #991b1b].zip(badges).each do |color, badge|
      assert_includes badge["style"], "background:#{color};"
      assert_nil badge.parent.next_element
    end
    assert_equal 3, html.css("td div").count { |entry| entry.text == "Sector en planilla: Domo Calbuco" }
  end
end
