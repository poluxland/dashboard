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
end
