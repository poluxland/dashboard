require "test_helper"

class MantencionMailerTest < ActionMailer::TestCase
  test "envia el informe de la semana anterior" do
    email = MantencionMailer.weekly_report(reference_date: Date.new(2026, 9, 7))

    assert_equal [
      "jose.jerez@msindustrial.cl",
      "julio.alvear@msindustrial.cl",
      "fernando.gonzalez@msindustrial.cl",
      "martin.llancafil@meloncementos.cl",
      "daniel.garrido@meloncementos.cl",
      "francisco.salgado@meloncementos.cl",
      "gerardo.martinez@meloncementos.cl",
      "johnny.rute@meloncementos.cl",
      "camila.birke@msindustrial.cl",
      "juan.belmar@meloncementos.cl",
      "manuel.sepulveda@meloncementos.cl",
      "alex.rioseco@meloncementos.cl",
      "gabriel.arancibia@meloncementos.cl",
      "alex.dorante@msindustrial.cl",
      "mario.santibanez@meloncementos.cl",
      "maximiliano.perez@meloncementos.cl",
      "efrain.mindiola@meloncementos.cl",
      "hector.ampuero@msindustrial.cl",
      "luis.navas@msindustrial.cl",
      "isabel.tapia@meloncementos.cl",
      "jose.opazo-externo@melonservicios.cl",
      "gari.aguilera@meloncementos.cl",
      "pia.villegas@meloncementos.cl",
      "carolina.vera@meloncementos.cl",
      "moira.cisternas@meloncementos.cl",
      "exequiel.moya@msindustrial.cl",
      "rodrigo.bravo@meloncementos.cl",
      "hans.velasquez@msindustrial.cl",
      "helmut.brandau@meloncementos.cl"
    ], email.to
    assert_equal 29, email.to.uniq.size
    assert_equal [ "control@msindustrial.cl" ], email.from
    assert_equal "Informe semanal de mantenciones · Semana 36", email.subject
    assert_match "Mantenciones · Semana 36", email.html_part.body.to_s
    assert_match "Programadas", email.html_part.body.to_s
    assert_match "No programadas", email.html_part.body.to_s
    assert_match "Con OT", email.html_part.body.to_s
    assert_match "Ejecutado", email.html_part.body.to_s
    assert_no_match "Estado promedio", email.html_part.body.to_s
    assert_match "Estado de ejecución", email.html_part.body.to_s
    assert_no_match "Tipo de mantención", email.html_part.body.to_s
    assert_no_match "Horas por especialidad", email.html_part.body.to_s
    assert_match "Tareas de la semana", email.html_part.body.to_s
    assert_match "Inspección de equipos eléctricos", email.html_part.body.to_s
    assert_match "100%", email.html_part.body.to_s
    assert_match "Cambio de motor", email.html_part.body.to_s
    assert_match "50%", email.html_part.body.to_s
    assert_match "Trabajo realizado sin observaciones.", email.html_part.body.to_s
    assert_no_match "Comentarios:", email.html_part.body.to_s
    assert_match "SEMANA 36", email.text_part.body.to_s
    assert_match "Cumplimiento: 100%", email.text_part.body.to_s
    assert_match "Trabajo realizado sin observaciones.", email.text_part.body.to_s
    assert_no_match "Comentarios:", email.text_part.body.to_s
  end
end
