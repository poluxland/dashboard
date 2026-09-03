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
    blank_row = [ nil, nil, "Eléctrico", nil, nil, nil, nil, nil, nil, nil, nil, nil ]
    invalid_week_row = [
      "16+", Date.new(2026, 4, 17), "Eléctrico", "P423", "VV02", "Preventivo",
      "Mantenimiento de válvulas", "Plan", 1, 55990004, 2, nil
    ]
    invalid_row = [
      36, Date.new(2026, 9, 4), "Eléctrico", "P513", "PM01", "Preventivo",
      "Prueba inválida", "Plan", 10.1, 55990003, 1, nil
    ]

    with_mantencion_xlsx([ electrical_row, mechanical_row, electrical_row, blank_row, invalid_week_row, invalid_row ]) do |upload|
      result = nil

      assert_difference("Mantencion.count", 3) do
        result = MantencionExcelImporter.new(upload).call
      end

      assert_equal 3, result.created
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
