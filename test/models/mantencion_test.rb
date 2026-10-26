require "test_helper"

class MantencionTest < ActiveSupport::TestCase
  test "agrega P a áreas con tres dígitos iniciales sin modificar códigos" do
    { "513" => "P513", "5133" => "P5133", " 513x " => "P513X",
      "P513" => "P513", "51X" => "51X", "A513" => "A513", nil => nil }.each do |input, expected|
      record = Mantencion.new(area: input, codigo: "513X")
      record.validate
      assert_equal expected, record.area if expected
      assert_nil record.area unless expected
      assert_equal "513X", record.codigo
    end
  end

  test "migración corrige solo áreas que comienzan con tres dígitos" do
    require Rails.root.join("db/migrate/20261026180000_prefix_numeric_mantencion_areas")
    record = mantenciones(:one)
    record.update_columns(area: "513X")
    original = mantenciones(:two).attributes
    migration = PrefixNumericMantencionAreas.new
    migration.suppress_messages { migration.up }
    assert_equal "P513X", record.reload.area
    assert_equal original, mantenciones(:two).reload.attributes
    migration.suppress_messages { migration.up }
    assert_equal "P513X", record.reload.area
  end

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
    assert_equal "Correctivo Programado", mantencion.tipo_mantencion
    assert_equal "Plan", mantencion.planificacion
    assert_equal "55387467", mantencion.numero_ot
  end

  test "normaliza variantes conocidas de planificación" do
    assert_equal "Adicional", Mantencion.canonical_planning("adicional")
    assert_equal "Adicional", Mantencion.canonical_planning("Adicionsl")
    assert_equal "Adicional", Mantencion.canonical_planning("Adcional")
    assert_equal "Plan", Mantencion.canonical_planning("PALN")
    assert_equal "Reprogramado", Mantencion.canonical_planning("REPROGRAMADO")
    assert_equal "Reprogramado", Mantencion.canonical_planning("Programado", maintenance_type: "Reprogramar")
    assert_equal "Adicional", Mantencion.canonical_planning(nil, maintenance_type: "Correctivo No programado")
    assert_equal "Plan", Mantencion.canonical_planning("Programado", maintenance_type: "Preventiva")
  end

  test "define las opciones cerradas del formulario" do
    assert_equal [ "Plan", "Adicional", "Reprogramado" ], Mantencion::PLANNING_OPTIONS
    assert_equal [ "Preventiva", "Correctivo Programado", "Correctivo No programado", "Reprogramar" ],
                 Mantencion::MAINTENANCE_TYPE_OPTIONS
  end

  test "clasifica tipos ambiguos usando la planificación" do
    assert_equal "Preventiva", Mantencion.canonical_maintenance_type("prventiva", planning: "Plan")
    assert_equal "Correctivo Programado", Mantencion.canonical_maintenance_type("Mejora", planning: "Plan")
    assert_equal "Correctivo No programado", Mantencion.canonical_maintenance_type("Adicional", planning: "Adicional")
    assert_equal "Correctivo No programado", Mantencion.canonical_maintenance_type(nil, planning: nil)
    assert_equal "Reprogramar", Mantencion.canonical_maintenance_type("Correctivo Programado", planning: "Reprogramado")
  end

  test "completa el estado vacío cuando hay comentarios u horas" do
    with_comments = Mantencion.new(comentarios: "Trabajo terminado")
    with_duration = Mantencion.new(duracion: 2.5)
    without_evidence = Mantencion.new(comentarios: " ", duracion: 0)

    with_comments.validate
    with_duration.validate
    without_evidence.validate

    assert_equal 100, with_comments.estado
    assert_equal 100, with_duration.estado
    assert_nil without_evidence.estado
  end

  test "conserva cualquier estado que ya tenga un número" do
    not_started = Mantencion.new(estado: 0, comentarios: "Pendiente")
    in_progress = Mantencion.new(estado: 50, duracion: 2)

    not_started.validate
    in_progress.validate

    assert_equal 0, not_started.estado
    assert_equal 50, in_progress.estado
  end
end
