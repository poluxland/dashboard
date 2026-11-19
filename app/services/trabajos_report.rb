class TrabajosReport
  attr_reader :meses, :pendientes, :sin_op, :con_op, :en_ejecucion, :ventas, :grafico

  def initialize(today:)
    @meses = (0..3).map { |offset| today.beginning_of_month << offset }
    trabajos = Trabajo.where(planta: Trabajo::PLANTAS.keys)
    terminados = trabajos.terminados
    @pendientes = terminados.group(:planta).sum(:total)
    @sin_op = terminados.sin_op.group(:planta).sum(:total)
    @con_op = terminados.con_op.group(:planta).sum(:total)
    @en_ejecucion = trabajos.en_ejecucion.group(:planta).sum(:total)

    @ventas = Hash.new(0)
    trabajos.finalizados.where(fecha_termino: meses.last..today.end_of_month)
      .group(:planta, :fecha_termino).sum(:total).each do |(planta, fecha), total|
        @ventas[[ planta, fecha.beginning_of_month ]] += total
      end

    por_planta = trabajos.finalizados.where(fecha_termino: (today << 12)..today)
      .group(:planta, :fecha_termino).order(:fecha_termino).sum(:total)
      .group_by { |(planta, _fecha), _total| planta }
    @grafico = Trabajo::PLANTAS.map do |planta, sigla|
      {
        label: sigla,
        data: por_planta.fetch(planta, []).map { |(_planta, fecha), total| [ fecha.iso8601, total ] }
      }
    end
  end
end
