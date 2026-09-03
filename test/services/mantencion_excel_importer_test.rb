require "test_helper"

class MantencionExcelImporterTest < ActiveSupport::TestCase
  test "importa datos, convierte porcentajes y evita duplicados" do
    electrical_row = [
      36, Date.new(2026, 9, 2), "Eléctrico", "P416", "WT01", "Preventivo",
      "Inspección eléctrica", "Plan", 1, 55990001, 2, "Trabajo finalizado"
    ]
    mechanical_row = [
      36, Date.new(2026, 9, 3), "Mecánico", 426, "FA01", "Correctivo Programado",
      "Cambio de motor", "Adicional", 0.5, 55990002, 3.5, "En ejecución"
    ]
    whole_percentage_row = [
      36, Date.new(2026, 9, 4), "MECÁNICA", " p426 ", "fa02", "PREVENTIVO",
      "Inspección de cinta", " adicional ", 100, 55990005, 1, "Trabajo finalizado"
    ]
    electrical_duplicate = electrical_row.dup
    electrical_duplicate[2] = "ELÉCTRICO"
    electrical_duplicate[3] = "p416"
    electrical_duplicate[5] = "preventivo"
    electrical_duplicate[7] = " plan "
    blank_row = [ nil, nil, "Eléctrico", nil, nil, nil, nil, nil, nil, nil, nil, nil ]
    invalid_week_row = [
      "16+", Date.new(2026, 4, 17), "Eléctrico", "P423", "VV02", "Preventivo",
      "Mantenimiento de válvulas", "Plan", 1, 55990004, 2, nil
    ]
    invalid_row = [
      36, Date.new(2026, 9, 4), "Eléctrico", "P513", "PM01", "Preventivo",
      "Prueba inválida", "Plan", 101, 55990003, 1, nil
    ]

    rows = [
      electrical_row,
      mechanical_row,
      whole_percentage_row,
      electrical_duplicate,
      blank_row,
      invalid_week_row,
      invalid_row
    ]

    with_mantencion_xlsx(rows) do |upload|
      result = nil

      assert_difference("Mantencion.count", 4) do
        result = MantencionExcelImporter.new(upload).call
      end

      assert_equal 4, result.created
      assert_equal 1, result.duplicates
      assert_equal 1, result.skipped
      assert_equal 1, result.corrected
      assert_equal 1, result.errors.size

      electrical = Mantencion.find_by!(numero_ot: "55990001")
      mechanical = Mantencion.find_by!(numero_ot: "55990002")
      assert_equal 100, electrical.estado
      assert_equal 50, mechanical.estado
      assert_equal "426", mechanical.area
      assert_equal BigDecimal("3.5"), mechanical.duracion
      whole_percentage = Mantencion.find_by!(numero_ot: "55990005")
      assert_equal 100, whole_percentage.estado
      assert_equal "Mecánico", whole_percentage.especialidad
      assert_equal "P426", whole_percentage.area
      assert_equal "FA02", whole_percentage.codigo
      assert_equal "Adicional", whole_percentage.planificacion
      assert_equal 16, Mantencion.find_by!(numero_ot: "55990004").semana
    end
  end

  test "rechaza archivos con columnas diferentes" do
    with_mantencion_xlsx([]) do |upload|
      workbook = Roo::Excelx.new(upload.tempfile.path)
      assert_equal MANTENCION_HEADERS, workbook.sheet(0).row(1)
    end

    file = Tempfile.new([ "incorrecto", ".xlsx" ])
    package = Axlsx::Package.new
    package.workbook.add_worksheet(name: "Incorrecto") { |sheet| sheet.add_row [ "Otra columna" ] }
    package.serialize(file.path)
    file.rewind
    upload = ActionDispatch::Http::UploadedFile.new(filename: "incorrecto.xlsx", tempfile: file)

    assert_raises(MantencionExcelImporter::InvalidSpreadsheet) do
      MantencionExcelImporter.new(upload).call
    end
  ensure
    file&.close!
  end
end
