require "axlsx"
require "tempfile"

module MantencionXlsxTestHelper
  MANTENCION_HEADERS = [
    "Semana", "Fecha", "Tipo", "Área", "Código", "Tipo",
    "Actividad", "Planificación", "Estado", "N° OT", "Duracion", "Comentarios"
  ].freeze

  def with_mantencion_xlsx(rows)
    file = Tempfile.new([ "mantenciones", ".xlsx" ])
    package = Axlsx::Package.new

    package.workbook.add_worksheet(name: "Informe") do |sheet|
      date_style = package.workbook.styles.add_style(format_code: "dd/mm/yyyy")
      percentage_style = package.workbook.styles.add_style(format_code: "0%")
      sheet.add_row MANTENCION_HEADERS

      rows.each do |row|
        styles = Array.new(MANTENCION_HEADERS.length)
        styles[1] = date_style
        styles[8] = percentage_style
        sheet.add_row row, style: styles
      end
    end

    package.serialize(file.path)
    file.rewind

    upload = Rack::Test::UploadedFile.new(
      file.path,
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      true,
      original_filename: "mantenciones.xlsx"
    )

    yield upload
  ensure
    file&.close!
  end
end
