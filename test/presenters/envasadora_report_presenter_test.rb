require "test_helper"

class EnvasadoraReportPresenterTest < ActiveSupport::TestCase
  def sample(**attributes)
    EnvasadoraReport.create!({
      date: Date.current, turno: "TM", author_email: "jose.jerez@msindustrial.cl",
      silo19a: 16, silo19b: 16, silo20a: 30, silo20b: 30,
      silo21a: 21, silo21b: 26, silo22a: 20, silo22b: 20, silo27: 11, silo28: 12,
      especialsacos: 245, bigbagespecial: 66, bigbagextra: 48, bigbag_extra_retiro: 142,
      prodhaver: 7408, horas_haver: "3.5", comentarios_haver: "Dureza en regueras",
      silos3000tolva1: "Extra", ns30001: 25, plastificado_especial_soluble_completo: 4
    }.merge(attributes))
  end

  test "original example preserves totals production and hopper estimates" do
    tables = EnvasadoraReportPresenter.new(sample).tables.index_by { |table| table[:title] }
    assert_equal [ "Cemento Extra silo y piso", "2.098", "—", "—" ], tables["Inventario por Tipo"][:rows].first
    assert_equal [ "Total", "13.091", "—", "—" ], tables["Inventario por Tipo"][:rows].last
    assert_equal [ "Haver", "7.408", "61", "3,5", "53", "Dureza en regueras" ], tables["Producciones"][:rows].first
    assert_equal [ "Silos 3000", "Tolva 1", "Extra", "25", "37" ], tables["Nivel tolvas"][:rows].first
    assert_includes tables["Inventario de Sacos"][:rows], [ "Especial plastificado soluble completo", "7", "—", "—" ]
    assert_equal [ "Inventario por Tipo", "Inventario de Sacos", "Inventario de Big Bags", "Inventario de Silos", "Inventario Total combinado", "Despachos", "Producciones", "Nivel tolvas", "Calles operativas", "Estado de calles", "Enjuagues" ], tables.keys
  end

  test "sack and bigbag comparisons retain separate shift values and dynamic cement labels" do
    sample
    report = sample(turno: "TT", silo19_cement: "HPM", especialsacos: 300, bigbagextra: 60)
    tables = EnvasadoraReportPresenter.new(report).tables.index_by { |table| table[:title] }
    assert_equal [ "Especial", "245", "300", "—" ], tables["Inventario de Sacos"][:rows].first
    assert_equal [ "Bigbag extra piso", "48", "60", "—" ], tables["Inventario de Big Bags"][:rows].first
    assert_includes tables["Inventario Total combinado"][:rows], [ "Cemento HPM en silos", "0", "1.400", "—" ]
    assert_includes tables["Inventario Total combinado"][:rows], [ "Cemento Extra en silos", "2.050", "650", "—" ]
  end

  test "dispatch and combined inventory show independent values for all three shifts" do
    sample(especial_sacos: 213)
    sample(turno: "TT", especial_sacos: 150, silo19_cement: "HPM", especialsacos: 300)
    report = sample(turno: "TN", especial_sacos: 80, silo19_cement: "Ultra", especialsacos: 100)
    tables = EnvasadoraReportPresenter.new(report).tables.index_by { |table| table[:title] }
    assert_equal [ "Producto (t)", "TM", "TT", "TN" ], tables["Despachos"][:headers]
    assert_equal [ "Especial sacos", "213", "150", "80" ], tables["Despachos"][:rows].first
    combined = tables["Inventario Total combinado"]
    assert_equal [ "Producto (t)", "TM", "TT", "TN" ], combined[:headers]
    assert_includes combined[:rows], [ "Cemento Extra en silos", "2.050", "650", "650" ]
    assert_includes combined[:rows], [ "Cemento Ultra en silos", "1.800", "1.800", "3.200" ]
    assert_includes combined[:rows], [ "Cemento HPM en silos", "0", "1.400", "0" ]
    assert_includes combined[:rows], [ "Cemento Especial en piso", "311", "366", "166" ]
    assert_equal [ "Total combinado", "13.091", "13.146", "12.946" ], combined[:rows].last
  end

  test "fractional measures and sub-hour production remain visible and meaningful" do
    report = sample(silo19a: "16.25", horas_haver: "0.5", prodhaver: 1000)
    tables = EnvasadoraReportPresenter.new(report).tables.index_by { |table| table[:title] }
    assert_equal "16,25", tables["Inventario de Silos"][:rows].first[2]
    assert_equal "0,5", tables["Producciones"][:rows].first[3]
    assert_equal "50", tables["Producciones"][:rows].first[4]
  end
end
