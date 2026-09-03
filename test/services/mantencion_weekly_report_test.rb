require "test_helper"

class MantencionWeeklyReportTest < ActiveSupport::TestCase
  test "resume la semana completa anterior" do
    report = MantencionWeeklyReport.new(reference_date: Date.new(2026, 9, 7))

    assert_equal Date.new(2026, 8, 31), report.start_date
    assert_equal Date.new(2026, 9, 6), report.end_date
    assert_equal 36, report.week_number
    assert_equal 2, report.total
    assert_equal 1, report.completed
    assert_equal 75.0, report.average_state
    assert_equal 5.5, report.total_duration
  end

  test "genera los grupos normalizados para los graficos" do
    report = MantencionWeeklyReport.new(reference_date: Date.new(2026, 9, 7))
    charts = report.chart_groups.index_by { |chart| chart[:title] }

    assert_equal [ "Adicional", "Plan" ], charts.fetch("Planificación")[:rows].map { |row| row[:label] }
    assert_equal [ "Eléctrico", "Mecánico" ], charts.fetch("Especialidad")[:rows].map { |row| row[:label] }
    assert_equal 100.0, charts.fetch("Estado de ejecución")[:rows].sum { |row| row[:percentage] }
  end
end
