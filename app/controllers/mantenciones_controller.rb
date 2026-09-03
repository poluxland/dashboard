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
end
