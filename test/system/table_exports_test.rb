require "application_system_test_case"

class TableExportsSystemTest < ApplicationSystemTestCase
  test "downloads the on-site table without adding a second download to the recent trucks" do
    date = PmmTruck::CHILE.today
    material = PmmMaterial.create!(nombre: "Conchuela")
    PmmTruck.create!(fecha: date, pmm_material: material, patente: "ABC123",
      tipo: "Plano", llegada: "08:00", finished: false)
    visit pmm_trucks_path

    assert_selector "button[data-download-table]", count: 1
    assert_link "Descargar Excel", href: pmm_trucks_path(format: :xlsx), count: 1
    page.execute_script <<~JS
      const endpoint = document.querySelector("meta[name='table-export-url']").content
      const fetchTable = window.fetch
      window.fetch = (url, options) => {
        if (url === endpoint) document.body.dataset.tableExportRequest = options.body
        return fetchTable(url, options)
      }
      document.addEventListener("click", event => {
        if (!event.target.matches("a[download]")) return
        event.preventDefault()
        document.body.dataset.tableExportFile = event.target.download
      })
    JS

    within("section[aria-label='Camiones sin salida']") do
      find("button[data-download-table]", text: "Descargar Excel").click
    end

    assert_selector "body[data-table-export-file$='.xlsx']"
    table = JSON.parse(page.evaluate_script("document.body.dataset.tableExportRequest")).fetch("table_export")
    assert_equal 1, table.fetch("headers")
    assert_equal [
      [ "Fecha", "Patente", "Materia prima", "Tipo", "Llegada" ],
      [ date.strftime("%d/%m/%Y"), "ABC123", "Conchuela", "Plano", "08:00" ]
    ], table.fetch("rows")
  end
end
