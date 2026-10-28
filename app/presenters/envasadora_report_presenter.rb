# One ordered set of tables for the web, HTML email and plain-text email.
class EnvasadoraReportPresenter
  include ActionView::Helpers::NumberHelper
  include EnvasadoraReportsHelper

  SACKS = [
    [ "Especial", "especialsacos", 1 ],
    [ "Especial soluble", "especial_sacos_soluble", 1 ],
    [ "Especial plastificado completo", "plastificado_especial", "1.8" ],
    [ "Especial plastificado soluble completo", "plastificado_especial_soluble_completo", "1.8" ],
    [ "Especial plastificado lados", "plastificado_especial_lados", "1.8" ],
    [ "Especial plastificado zuncho", "plastificado_especial_zunchos", "1.8" ],
    [ "Extra", "extrsacos", 1 ],
    [ "Extra soluble", "extra_sacos_soluble", 1 ],
    [ "Extra plastificado completo", "plastificado_extra", "1.8" ],
    [ "Extra plastificado soluble completo", "plastificado_extra_soluble_completo", "1.8" ],
    [ "Extra plastificado zunchos", "plastificado_extra_zunchos", "1.8" ]
  ].freeze
  BIGBAGS = [
    [ "Bigbag extra piso", "bigbagextra", 1 ],
    [ "Bigbag Ultra", "bigbag_extra_retiro", 1 ],
    [ "Bigbag extra 1 t", "bigbagextra1", 1 ],
    [ "Extra peba 1350", "bigbagextra1350", 1 ],
    [ "Bigbag especial", "bigbagespecial", 1 ],
    [ "Bigbag super", "bigbagsuper", 1 ],
    [ "Bigbag Plus", "bigbagplus", 1 ]
  ].freeze
  PRODUCTION = [
    [ "Haver", "prodhaver", "horas_haver", "0.025", 12000, "comentarios_haver" ],
    [ "Ventomatic", "prodvento", "horas_vento", "0.025", 7000, "comentarios_vento" ],
    [ "Bigbag", "prodbb", "horas_bigbag", "1.5", 125, "comentarios_bigbag" ]
  ].freeze
  STREETS = [
    [ "Silo 28 Calle 3", "s28c3op", "s28c3cemento", "s28c3nota" ],
    [ "Silo 28 Calle 4", "s28c4op", "s28c4cemento", "s28c4nota" ],
    [ "Silo 28 Calle 5", "s28c5op", "s28c5cemento", "s28c5nota" ],
    [ "Silo 27 Calle 6", "s27c6op", "s27c7cemento", "s27c7nota" ],
    [ "Silos 3000 Calle 1", "s30c1op", "s30c1cemento", "s30c1nota" ],
    [ "Silos 3000 Calle 4", "s30c4op", "s30c4cemento", "s30c4nota" ],
    [ "Silos 3000 Calle 5", "s30c5op", "s30c5cemento", "s30c5nota" ]
  ].freeze

  def initialize(report)
    @report = report
    @daily = report.daily_reports
    @inventories = @daily.transform_values(&:inventory)
    primary = %w[Extra Ultra Especial S4200]
    extra = EnvasadoraReport::CEMENTS - primary
    @cements = primary + extra.select do |cement|
      @daily.values.any? do |record|
        record.inventory[cement][:total].positive? || EnvasadoraReport::SILOS.keys.any? { |id| record.public_send("silo#{id}_cement") == cement }
      end
    end
  end

  def tables
    [
      inventory_table,
      shift_table("Inventario de Sacos", SACKS),
      shift_table("Inventario de Big Bags", BIGBAGS),
      silos_table,
      combined_table,
      dispatch_table,
      production_table,
      hoppers_table,
      operative_streets_table,
      streets_table,
      rinses_table
    ]
  end

  private

  def table(title, headers, rows)
    { title: title, headers: headers, rows: rows }
  end

  def number(value)
    envasadora_number(value)
  end

  def inventory_table
    rows = @cements.map do |cement|
      [ "Cemento #{cement} silo y piso" ] + EnvasadoraReport::SHIFTS.keys.map do |shift|
        @inventories[shift] ? number(@inventories[shift][cement][:total]) : "—"
      end
    end
    rows << [ "Total" ] + EnvasadoraReport::SHIFTS.keys.map { |shift| @daily[shift] ? number(@daily[shift].total_tons) : "—" }
    table("Inventario por Tipo", [ "Producto (t)", "TM", "TT", "TN" ], rows)
  end

  def shift_table(title, fields)
    rows = fields.map do |label, field, factor|
      [ label ] + EnvasadoraReport::SHIFTS.keys.map do |shift|
        @daily[shift] ? number(@daily[shift].public_send(field) * factor.to_d) : "—"
      end
    end
    table(title, [ "Producto (t)", "TM", "TT", "TN" ], rows)
  end

  def silos_table
    rows = [ 19, 20, 21, 22, 28, 27 ].map do |id|
      readings = EnvasadoraReport::SILOS.fetch(id)[:readings]
      [ "#{id} (#{@report.public_send("silo#{id}_cement")})", number(@report.silo_tons(id)) ] +
        2.times.map { |index| readings[index] ? envasadora_decimal(@report.public_send(readings[index])) : "—" }
    end
    table("Inventario de Silos", [ "Silo (producto)", "Stock (t)", "M1 (m)", "M2 (m)" ], rows)
  end

  def combined_table
    rows = @cements.flat_map do |cement|
      { silo: "silos", floor: "piso" }.map do |component, label|
        [ "Cemento #{cement} en #{label}" ] + EnvasadoraReport::SHIFTS.keys.map do |shift|
          @inventories[shift] ? number(@inventories[shift][cement][component]) : "—"
        end
      end
    end
    rows << [ "Total combinado" ] + EnvasadoraReport::SHIFTS.keys.map { |shift| @daily[shift] ? number(@daily[shift].total_tons) : "—" }
    table("Inventario Total combinado", [ "Producto (t)", "TM", "TT", "TN" ], rows)
  end

  def dispatch_table
    order = %w[especial_sacos extra_sacos especial_bigbag extra_bigbag super_bigbag ultra_bigbag especial_granel extra_granel super_3300_granel super_4200_granel]
    labels = EnvasadoraReport::GROUPS.fetch("Despacho").index_by { |field| field["name"] }
    shift_table("Despachos", order.map { |field| [ labels.fetch(field)["label"], field, 1 ] })
  end

  def production_table
    rows = PRODUCTION.map do |label, quantity, hours_field, factor, goal, comment|
      units = @report.public_send(quantity)
      hours = @report.public_send(hours_field)
      # The original report truncates compliance, but rounds tonnes per hour.
      compliance = [ (units * 100 / goal).floor, 100 ].min
      throughput = hours.positive? ? units * factor.to_d / hours : 0
      [ label, number(units), number(compliance), envasadora_decimal(hours), number(throughput), @report.public_send(comment).presence || "—" ]
    end
    table("Producciones", [ "Equipo", "Unidades turno", "Cumplimiento (%)", "Horas prod.", "Rendimiento (t/h)", "Comentarios" ], rows)
  end

  def hoppers_table
    rows = EnvasadoraReport::HOPPERS.rotate(1).map do |label, cement, level, capacity|
      line, hopper = case label
      when /Silos 3000/ then [ "Silos 3000", label.sub("Silos 3000 tolva", "Tolva") ]
      when /Bigbag/ then [ "Bigbag", label.sub("Bigbag", "Silo") ]
      when /Vento/ then [ "Ventomatic", label.sub("Vento", "Silo") ]
      else [ "Silo 28", "Calle 5" ]
      end
      percentage = @report.public_send(level)
      # Preserve the original whole-tonne estimate (37.5 -> 37).
      [ line, hopper, @report.public_send(cement).presence || "Sin informar", number(percentage), number((percentage * capacity / 100).floor) ]
    end
    table("Nivel tolvas", [ "Línea", "Tolva", "Producto", "Nivel (%)", "Toneladas" ], rows)
  end

  def operative_streets_table
    rows = [ [ "Silo 27", "callesilo27" ], [ "Silo 28", "callesilo28" ], [ "Planta 1", "callesplanta1" ] ].map { |label, field| [ label, number(@report.public_send(field)) ] }
    table("Calles operativas", [ "Calles", "Operativas" ], rows)
  end

  def streets_table
    rows = STREETS.map { |label, *fields| [ label ] + fields.map { |field| @report.public_send(field).presence || "—" } }
    table("Estado de calles", [ "Calle", "Estado", "Cemento", "Comentarios" ], rows)
  end

  def rinses_table
    rows = EnvasadoraReport::GROUPS.fetch("Enjuagues").map { |field| [ field["label"], number(@report.public_send(field["name"])) ] }
    table("Enjuagues", [ "Producto", "Cantidad" ], rows)
  end
end
