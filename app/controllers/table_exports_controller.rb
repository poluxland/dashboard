class TableExportsController < ApplicationController
  XLSX_MIME = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet".freeze
  MAX_CELLS = 120_000
  MAX_COLUMNS = 256

  # This endpoint formats submitted cells and does not read any application records.
  skip_before_action :authenticate_user!
  rate_limit to: 12, within: 1.minute, only: :create
  wrap_parameters false

  def create
    return head :unsupported_media_type unless request.media_type == "application/json"
    return head 413 if request.content_length.to_i > 4.megabytes

    table = params[:table_export]
    return head :unprocessable_entity unless table.is_a?(ActionController::Parameters)

    rows = table[:rows]
    headers = table[:headers]
    return head :unprocessable_entity unless valid_rows?(rows) && headers.is_a?(Integer) && headers.between?(0, rows.size)

    title = table[:title]
    name = title.first(120).parameterize.presence if title.is_a?(String)
    response.headers["Cache-Control"] = "no-store"
    send_data workbook(rows, headers), filename: "#{name || "tabla"}.xlsx", type: XLSX_MIME
  end

  private

  def valid_rows?(rows)
    return false unless rows.is_a?(Array) && rows.size.between?(1, 20_000)
    return false unless rows.all? { |row| row.is_a?(Array) && row.size.between?(1, MAX_COLUMNS) }
    return false if rows.sum(&:size) > MAX_CELLS

    rows.all? { |row| row.all? { |cell| cell.is_a?(String) && cell.size <= 32_767 } }
  end

  def workbook(rows, headers)
    package = Axlsx::Package.new
    header = package.workbook.styles.add_style(b: true, fg_color: "FFFFFF", bg_color: "183153")
    package.workbook.add_worksheet(name: "Tabla", escape_formulas: true) do |sheet|
      rows.each_with_index do |row, index|
        sheet.add_row row, types: :string, style: (header if index < headers)
      end
      if headers.positive?
        sheet.sheet_view.pane do |pane|
          pane.top_left_cell = "A#{headers + 1}"
          pane.state = :frozen
          pane.y_split = headers
        end
      end
    end
    package.to_stream.read
  end
end
