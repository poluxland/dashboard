require "application_system_test_case"

class OtsTest < ApplicationSystemTestCase
  setup do
    @ot = ots(:one)
  end

  test "visiting the index" do
    visit ots_url
    assert_selector "h1", text: "Ots"
  end

  test "should create ot" do
    visit ots_url
    click_on "New ot"

    fill_in "Actividad semanal", with: @ot.actividad_semanal
    fill_in "Area", with: @ot.area
    fill_in "Cantidad", with: @ot.cantidad
    fill_in "Causa", with: @ot.causa
    fill_in "Cc", with: @ot.cc
    fill_in "Cod rep", with: @ot.cod_rep
    fill_in "Codigo", with: @ot.codigo
    fill_in "Comentarios", with: @ot.comentarios
    fill_in "Contratista", with: @ot.contratista
    fill_in "Cotizacion", with: @ot.cotizacion
    fill_in "Duracion hr", with: @ot.duracion_hr
    fill_in "Esp", with: @ot.esp
    fill_in "Estado", with: @ot.estado
    fill_in "Frecuencia", with: @ot.frecuencia
    fill_in "Hh", with: @ot.hh
    fill_in "Item", with: @ot.item
    fill_in "N personas", with: @ot.n_personas
    fill_in "Responsable", with: @ot.responsable
    fill_in "Sem ejec", with: @ot.sem_ejec
    fill_in "Semana", with: @ot.semana
    fill_in "Servicio", with: @ot.servicio
    fill_in "Tipo ot", with: @ot.tipo_ot
    fill_in "Unitario", with: @ot.unitario
    click_on "Create Ot"

    assert_text "Ot was successfully created"
    click_on "Back"
  end

  test "should update Ot" do
    visit ot_url(@ot)
    click_on "Edit this ot", match: :first

    fill_in "Actividad semanal", with: @ot.actividad_semanal
    fill_in "Area", with: @ot.area
    fill_in "Cantidad", with: @ot.cantidad
    fill_in "Causa", with: @ot.causa
    fill_in "Cc", with: @ot.cc
    fill_in "Cod rep", with: @ot.cod_rep
    fill_in "Codigo", with: @ot.codigo
    fill_in "Comentarios", with: @ot.comentarios
    fill_in "Contratista", with: @ot.contratista
    fill_in "Cotizacion", with: @ot.cotizacion
    fill_in "Duracion hr", with: @ot.duracion_hr
    fill_in "Esp", with: @ot.esp
    fill_in "Estado", with: @ot.estado
    fill_in "Frecuencia", with: @ot.frecuencia
    fill_in "Hh", with: @ot.hh
    fill_in "Item", with: @ot.item
    fill_in "N personas", with: @ot.n_personas
    fill_in "Responsable", with: @ot.responsable
    fill_in "Sem ejec", with: @ot.sem_ejec
    fill_in "Semana", with: @ot.semana
    fill_in "Servicio", with: @ot.servicio
    fill_in "Tipo ot", with: @ot.tipo_ot
    fill_in "Unitario", with: @ot.unitario
    click_on "Update Ot"

    assert_text "Ot was successfully updated"
    click_on "Back"
  end

  test "should destroy Ot" do
    visit ot_url(@ot)
    click_on "Destroy this ot", match: :first

    assert_text "Ot was successfully destroyed"
  end
end
