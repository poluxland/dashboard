require "test_helper"
require "zip"

class TableExportsTest < ActionDispatch::IntegrationTest
  test "downloads the submitted table with its header and preserves text safely" do
    post table_export_path, as: :json, params: {
      table_export: {
        title: "Estado de camiones",
        headers: 1,
        rows: [ [ "Patente", "Observación" ], [ "001", "=1+1" ] ]
      }
    }

    assert_response :success
    assert_equal "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", response.media_type
    assert_includes response.headers["Content-Disposition"], "estado-de-camiones.xlsx"
    assert_includes response.headers["Cache-Control"], "no-store"
    Zip::File.open_buffer(response.body) do |workbook|
      sheet = workbook.read("xl/worksheets/sheet1.xml")
      assert_includes sheet, "Patente"
      assert_includes sheet, "001"
      assert_includes sheet, "=1+1"
      assert_includes sheet, 'state="frozen"'
      assert_no_match(/<f[ >]/, sheet)
    end
  end

  test "rejects invalid cell data and header counts" do
    [
      { rows: [ "Patente" ], headers: 1 },
      { rows: [ [ nil ] ], headers: 0 },
      { rows: [ [ "Patente" ] ], headers: 2 }
    ].each do |table|
      post table_export_path, as: :json, params: { table_export: table }

      assert_response :unprocessable_entity
    end
  end
end
