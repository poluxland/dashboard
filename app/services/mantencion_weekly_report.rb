class MantencionWeeklyReport
  PALETTE = %w[#2563eb #16a34a #f59e0b #dc2626 #7c3aed #0891b2 #db2777 #65a30d #ea580c #4f46e5 #64748b].freeze

  attr_reader :start_date, :end_date, :records

  def self.local_today
    Time.find_zone!("America/Santiago").today
  end

  def initialize(reference_date: self.class.local_today, scope: Mantencion.all)
    reference_date = reference_date.to_date
    @start_date = reference_date.beginning_of_week - 1.week
    @end_date = @start_date.end_of_week
    @records = scope.where(fecha: start_date..end_date).order(:fecha, :created_at).to_a
  end

  def week_number
    start_date.cweek
  end

  def total
    records.size
  end

  def planned_count
    @planned_count ||= records.count do |record|
      Mantencion.canonical_planning(record.planificacion) == "Plan"
    end
  end

  def unplanned_count
    total - planned_count
  end

  def with_ot_count
    records.count { |record| record.numero_ot.present? }
  end

  def average_state
    values = records.filter_map(&:estado).map(&:to_f)
    (values.sum / values.size).round(1) if values.any?
  end

  def chart_groups
    [
      chart("Estado de ejecución", state_counts),
      chart("Planificación", category_counts("Sin planificación") { |record| Mantencion.canonical_planning(record.planificacion) }),
      chart("Especialidad", category_counts("Sin especialidad") { |record| Mantencion.canonical_specialty(record.especialidad) }),
      chart("Áreas con más mantenciones", area_counts)
    ]
  end

  private

  def state_counts
    counts = Hash.new(0)

    records.each do |record|
      label = if record.estado.nil?
        "Sin estado"
      elsif record.estado.zero?
        "No iniciada (0%)"
      elsif record.estado >= 100
        "Completada (100%)"
      else
        "En progreso (1–99%)"
      end
      counts[label] += 1
    end

    ordered_counts(counts)
  end

  def category_counts(fallback)
    counts = records.each_with_object(Hash.new(0)) do |record, result|
      result[yield(record).presence || fallback] += 1
    end

    ordered_counts(counts)
  end

  def area_counts
    counts = category_counts("Sin área") { |record| Mantencion.canonical_identifier(record.area) }
    top_areas = counts.first(10)
    other_total = counts.drop(10).sum { |_label, value| value }
    top_areas << [ "Otras áreas", other_total ] if other_total.positive?
    top_areas.to_h
  end

  def ordered_counts(counts)
    counts.sort_by { |label, value| [ -value, label ] }.to_h
  end

  def chart(title, counts, suffix: "")
    total_value = counts.values.sum.to_f
    rows = counts.map.with_index do |(label, value), index|
      {
        label: label,
        value: value,
        suffix: suffix,
        percentage: total_value.positive? ? ((value.to_f / total_value) * 100).round(1) : 0,
        color: PALETTE[index % PALETTE.size]
      }
    end

    { title: title, rows: rows }
  end
end
