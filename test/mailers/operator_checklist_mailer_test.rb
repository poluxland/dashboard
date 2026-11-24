require "test_helper"

class OperatorChecklistMailerTest < ActionMailer::TestCase
  setup do
    @zone = Time.find_zone!("America/Santiago")
    @asset = MobileAsset.create!(code: "HQ01")
    @other_asset = MobileAsset.create!(code: "HQ02")
  end

  test "La Calera reports the latest checklist per asset in the preceding eight hours" do
    cutoff = @zone.local(2026, 11, 19, 6)
    checklist(@asset, cutoff - 8.hours, comments: "Reemplazado dentro del turno")
    checklist(@asset, cutoff - 1.minute, hour_meter: 313, operator: "María Soto", comments: "Comentario & foto",
              c3: "Si", c4: "No(grave)", c8: "No(leve)", c10: "Si")
    checklist(@asset, cutoff, comments: "Pertenece al turno siguiente")
    checklist(@other_asset, cutoff - 8.hours - 1.second, comments: "Fuera del turno anterior")
    checklist(@other_asset, cutoff - 8.hours, comments: "Inicio del turno", c1: "No(grave)")
    checklist(@other_asset, cutoff - 1.minute, plant: "PTM", comments: "Otra planta")

    email = OperatorChecklistMailer.report(plant: "LCA", scheduled_at: cutoff)
    html = Nokogiri::HTML(email.html_part.decoded)

    assert_equal %w[
      alejandro.olivares@msindustrial.cl
      claudio.tapia@msindustrial.cl
      claudio.villanueva@msindustrial.cl
      diego.castillo@msindustrial.cl
      fernando.gonzalez@msindustrial.cl
      hernan.martinez@msindustrial.cl
      hernan.martinezg@msindustrial.cl
      jose.jerez@msindustrial.cl
      marcos.prospero@msindustrial.cl
      marisela.alvarado@msindustrial.cl
      maryorie.fajardo@msindustrial.cl
      simon.rojas@msindustrial.cl
      supervisor.envasadora@msindustrial.cl
    ], email.to.sort
    assert_equal [ "Equipo", "Fecha y hora", "H", "Operador", "%", "Graves", "Leves", "Detalle graves",
                  "Detalle leves", "Comentarios" ], html.css("th").map(&:text)
    assert_equal [
      [ "HQ01", "19/11/2026 05:59", "313", "María Soto", "62,5", "1", "1", "Frenos", "Neumáticos", "Comentario & foto" ],
      [ "HQ02", "18/11/2026 22:00", "100", "Operador de prueba", "0", "1", "0", "Fugas", "—", "Inicio del turno" ]
    ], html.css("tbody tr").map { |row| row.css("td").map(&:text) }
    assert_includes email.text_part.decoded, "H 313 · Operador María Soto · % 62,5\n"
    assert_includes email.text_part.decoded, "Graves (1): Frenos"
  end

  test "Puerto Montt preserves every checklist from the previous Chilean day" do
    cutoff = Time.utc(2026, 11, 19, 12)
    checklist(@asset, @zone.local(2026, 11, 18), plant: "PTM", comments: "Primero")
    checklist(@asset, @zone.local(2026, 11, 18, 23, 59), plant: "PTM", comments: "Último")
    checklist(@asset, @zone.local(2026, 11, 19), plant: "PTM", comments: "Día siguiente")

    email = OperatorChecklistMailer.report(plant: "PTM", scheduled_at: cutoff)
    html = Nokogiri::HTML(email.html_part.decoded)

    assert_equal 11, email.to.size
    assert_includes email.to, "hernan.martinezg@msindustrial.cl"
    assert_includes email.to, "julio.alvear@msindustrial.cl"
    assert_equal "Checklist de operador · Puerto Montt · 18/11/2026", email.subject
    assert_equal [ "Último", "Primero" ], html.css("tbody tr").map { |row| row.css("td").last.text }
    assert_equal "—", html.css("tbody tr").first.css("td")[4].text
  end

  private

  def checklist(asset, created_at, plant: "LCA", **values)
    answers = EquipmentChecklist::QUESTIONS.keys.index_with("No aplica")
    EquipmentChecklist.create!(answers.merge(mobile_asset: asset, operator: "Operador de prueba", hour_meter: 100,
                                              c17: plant, created_at: created_at).merge(values))
  end
end
