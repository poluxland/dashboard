require "test_helper"

class MantencionTest < ActiveSupport::TestCase
  test "completa la semana desde la fecha" do
    mantencion = Mantencion.new(
      fecha: Date.new(2026, 1, 2),
      especialidad: "Eléctrico",
      actividad: "Inspección"
    )

    assert mantencion.valid?
    assert_equal 1, mantencion.semana
  end

  test "valida que estado sea un porcentaje" do
    mantencion = mantenciones(:one)
    mantencion.estado = 101

    assert_not mantencion.valid?
    assert mantencion.errors[:estado].any?
  end

  test "valida una duración no negativa" do
    mantencion = mantenciones(:one)
    mantencion.duracion = -1

    assert_not mantencion.valid?
    assert mantencion.errors[:duracion].any?
  end

  test "normaliza categorías e identificadores antes de guardar" do
    mantencion = Mantencion.new(
      fecha: Date.new(2026, 9, 2),
      especialidad: " MECÁNICA ",
      area: " p426 ",
      codigo: " fa01 ",
      tipo_mantencion: " CORRECTIVO   PROGRAMADO ",
      actividad: "Cambio de motor",
      planificacion: " plan ",
      numero_ot: " 55387467 "
    )

    assert mantencion.valid?
    assert_equal "Mecánico", mantencion.especialidad
    assert_equal "P426", mantencion.area
    assert_equal "FA01", mantencion.codigo
    assert_equal "Correctivo programado", mantencion.tipo_mantencion
    assert_equal "Plan", mantencion.planificacion
    assert_equal "55387467", mantencion.numero_ot
  end

  test "normaliza variantes conocidas de planificación" do
    assert_equal "Adicional", Mantencion.canonical_planning("adicional")
    assert_equal "Adicional", Mantencion.canonical_planning("Adicionsl")
    assert_equal "Reprogramar", Mantencion.canonical_planning("REPROGRAMADO")
  end
end
