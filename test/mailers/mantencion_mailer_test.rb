require "test_helper"

class MantencionMailerTest < ActionMailer::TestCase
  test "envia el informe de la semana anterior" do
    email = MantencionMailer.weekly_report(reference_date: Date.new(2026, 9, 7))

    assert_equal [ "jose.jerez@msindustrial.cl" ], email.to
    assert_equal [ "control@msindustrial.cl" ], email.from
    assert_equal "Informe semanal de mantenciones · Semana 36", email.subject
    assert_match "Mantenciones · Semana 36", email.html_part.body.to_s
    assert_match "Estado de ejecución", email.html_part.body.to_s
    assert_match "SEMANA 36", email.text_part.body.to_s
  end
end
