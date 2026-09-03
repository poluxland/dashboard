class MantencionesController < ApplicationController
  SPECIALTY_FILTERS = {
    "electrica" => {
      title: "Mantención eléctrica",
      description: "Informe de ejecución de mantenimiento eléctrico",
      default: "Eléctrico",
      values: %w[eléctrico eléctrica]
    },
    "mecanica" => {
      title: "Mantención mecánica",
      description: "Informe de ejecución de mantenimiento mecánico",
      default: "Mecánico",
      values: %w[mecánico mecánica]
    }
  }.freeze

  before_action :set_mantencion, only: %i[show edit update destroy]

  def index
    scope = Mantencion.order(fecha: :desc, created_at: :desc)
    filter = specialty_filter

    if filter
      scope = scope.where("LOWER(especialidad) IN (?)", filter[:values])
      @especialidad_filter = params[:especialidad]
      @page_title = filter[:title]
      @page_description = filter[:description]
    else
      @page_title = "Mantenciones"
      @page_description = "Registro de mantenciones eléctricas y mecánicas"
    end

    @pagy, @mantenciones = pagy(scope)
  end

  def graficos
    scope = Mantencion.order(:fecha)
    @available_years = Mantencion.where.not(fecha: nil).pluck(:fecha).map(&:year).uniq.sort.reverse
    @selected_year = params[:year].to_s if params[:year].to_s.match?(/\A\d{4}\z/)
    @selected_specialty = params[:especialidad].to_s if specialty_filter

    if @selected_year.present?
      year = @selected_year.to_i
      scope = scope.where(fecha: Date.new(year, 1, 1)..Date.new(year, 12, 31))
    end

    if (filter = specialty_filter)
      scope = scope.where("LOWER(especialidad) IN (?)", filter[:values])
    end

    build_chart_data(scope.to_a)
  end

  def show
  end

  def new
    today = Time.find_zone!("America/Santiago").today
    filter = specialty_filter
    @especialidad_filter = params[:especialidad] if filter
    @mantencion = Mantencion.new(
      fecha: today,
      semana: today.cweek,
      especialidad: filter&.fetch(:default) || "Eléctrico"
    )
  end

  def edit
  end

  def create
    @especialidad_filter = params[:especialidad] if specialty_filter
    @mantencion = Mantencion.new(mantencion_params)

    if @mantencion.save
      redirect_to mantenciones_path(especialidad: @especialidad_filter), notice: "Mantención creada correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @mantencion.update(mantencion_params)
      redirect_to mantenciones_path, notice: "Mantención actualizada correctamente.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @mantencion.destroy!
    redirect_to mantenciones_path, notice: "Mantención eliminada correctamente.", status: :see_other
  end

  private

  def set_mantencion
    @mantencion = Mantencion.find(params.expect(:id))
  end

  def specialty_filter
    SPECIALTY_FILTERS[params[:especialidad].to_s]
  end

  def mantencion_params
    params.expect(
      mantencion: [
        :semana,
        :fecha,
        :especialidad,
        :area,
        :codigo,
        :tipo_mantencion,
        :actividad,
        :planificacion,
        :estado,
        :numero_ot,
        :duracion,
        :comentarios
      ]
    )
  end

  def build_chart_data(records)
    states = records.filter_map(&:estado).map(&:to_f)

    @total_mantenciones = records.size
    @completed_mantenciones = states.count { |state| state >= 100 }
    @average_state = states.any? ? (states.sum / states.size).round(1) : nil
    @total_duration = records.sum { |record| record.duracion.to_f }.round(1)

    set_state_chart(records)
    set_category_chart(records, :planning, "Sin planificación") do |record|
      Mantencion.canonical_planning(record.planificacion)
    end
    set_category_chart(records, :specialty, "Sin especialidad") do |record|
      Mantencion.canonical_specialty(record.especialidad)
    end
    set_category_chart(records, :maintenance_type, "Sin tipo") do |record|
      Mantencion.canonical_maintenance_type(record.tipo_mantencion)
    end
    set_area_chart(records)
    set_week_charts(records)
    set_duration_chart(records)
  end

  def set_state_chart(records)
    counts = {
      "Completada (100%)" => 0,
      "En progreso (1–99%)" => 0,
      "No iniciada (0%)" => 0,
      "Sin estado" => 0
    }

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

    @state_labels, @state_values = chart_arrays(counts.reject { |_label, count| count.zero? })
  end

  def set_category_chart(records, name, fallback, &block)
    counts = grouped_counts(records, fallback:, &block)
    instance_variable_set("@#{name}_labels", counts.keys)
    instance_variable_set("@#{name}_values", counts.values)
  end

  def set_area_chart(records)
    counts = grouped_counts(records, fallback: "Sin área") do |record|
      Mantencion.canonical_identifier(record.area)
    end
    top_areas = counts.first(12)
    remaining_count = counts.drop(12).sum { |_label, count| count }
    top_areas << [ "Otras áreas", remaining_count ] if remaining_count.positive?
    @area_labels, @area_values = chart_arrays(top_areas.to_h)
  end

  def set_week_charts(records)
    by_week = records.select { |record| record.semana.present? }.group_by(&:semana).sort.to_h
    @week_labels = by_week.keys.map { |week| "S#{week}" }
    @week_values = by_week.values.map(&:size)
    @weekly_average_state_values = by_week.values.map do |week_records|
      states = week_records.filter_map(&:estado).map(&:to_f)
      (states.sum / states.size).round(1) if states.any?
    end
  end

  def set_duration_chart(records)
    duration_by_specialty = records.each_with_object(Hash.new(0.0)) do |record, totals|
      label = Mantencion.canonical_specialty(record.especialidad) || "Sin especialidad"
      totals[label] += record.duracion.to_f
    end
    duration_by_specialty = duration_by_specialty.sort_by { |label, _duration| label }.to_h
    @duration_labels = duration_by_specialty.keys
    @duration_values = duration_by_specialty.values.map { |duration| duration.round(1) }
  end

  def grouped_counts(records, fallback:)
    records.each_with_object(Hash.new(0)) do |record, counts|
      label = yield(record).presence || fallback
      counts[label] += 1
    end.sort_by { |label, count| [ -count, label ] }.to_h
  end

  def chart_arrays(counts)
    [ counts.keys, counts.values ]
  end
end
