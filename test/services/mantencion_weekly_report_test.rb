require "test_helper"

class MantencionWeeklyReportTest < ActiveSupport::TestCase
  test "resume la semana completa anterior" do
    report = MantencionWeeklyReport.new(reference_date: Date.new(2026, 9, 7))

    assert_equal Date.new(2026, 8, 31), report.start_date
    assert_equal Date.new(2026, 9, 6), report.end_date
    assert_equal 36, report.week_number
    assert_equal 2, report.total
    assert_equal 50.0, report.planned_percentage
    assert_equal 50.0, report.unplanned_percentage
    assert_equal 75.0, report.average_state
  end

  test "genera los grupos normalizados para los graficos" do
    report = MantencionWeeklyReport.new(reference_date: Date.new(2026, 9, 7))
    charts = report.chart_groups.index_by { |chart| chart[:title] }

    assert_equal [ "Adicional", "Plan" ], charts.fetch("Planificación")[:rows].map { |row| row[:label] }
    assert_equal [ "Eléctrico", "Mecánico" ], charts.fetch("Especialidad")[:rows].map { |row| row[:label] }
    assert_equal 100.0, charts.fetch("Estado de ejecución")[:rows].sum { |row| row[:percentage] }
    assert_not charts.key?("Tipo de mantención")
    assert_not charts.key?("Horas por especialidad")
  end

  test "considera programada solamente la planificacion Plan" do
    Mantencion.create!(
      fecha: Date.new(2026, 9, 4),
      especialidad: "Eléctrico",
      actividad: "Mantención programada",
      planificacion: "Programado"
    )

    report = MantencionWeeklyReport.new(reference_date: Date.new(2026, 9, 7))

    assert_equal 33.3, report.planned_percentage
    assert_equal 66.7, report.unplanned_percentage
  end
end
