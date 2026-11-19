class SopladosController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[new create]
  around_action :use_chilean_time
  before_action :set_soplado, only: %i[show edit update destroy]
  before_action :require_soplado_admin!, only: :destroy

  rate_limit to: 8, within: 1.minute, only: :create

  def index
    @filters = params.permit(:desde, :hasta, :supervisor)
    scope = Soplado.order(fecha: :desc, id: :desc)
    scope = scope.where(fecha: local_midnight(@filters[:desde])..) if @filters[:desde].present?
    scope = scope.where(fecha: ...local_midnight(@filters[:hasta], next_day: true)) if @filters[:hasta].present?
    if @filters[:supervisor].present?
      pattern = "%#{Soplado.sanitize_sql_like(@filters[:supervisor].strip)}%"
      scope = scope.where("supervisor ILIKE ?", pattern)
    end
    @pagy, @soplados = pagy(scope, limit: 30)
  rescue Date::Error
    redirect_to soplados_path, alert: "Indica fechas válidas para consultar el historial."
  end

  def show
  end

  def graficos
    @hasta = Time.current
    @desde = @hasta - 1.year
    fields = %i[horno presion5 presion1 presion2 presion3 presion4 presion6]
    rows = Soplado.where(fecha: @desde..@hasta).order(:fecha, :id).pluck(:fecha, *fields)
    @series = fields.each_with_index.to_h do |field, index|
      [ field, rows.filter_map { |row| [ row.first.to_i * 1000, row[index + 1] ] if row[index + 1] } ]
    end
  end

  def new
    @soplado = Soplado.new(fecha: Time.current)
  end

  def create
    @soplado = Soplado.new(soplado_params)
    if @soplado.save
      SopladoMailer.report(@soplado).deliver_later
      destination = signed_in? ? @soplado : new_soplado_path
      redirect_to destination, notice: "Registro de soplado TC guardado.", status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @soplado.update(soplado_params)
      redirect_to @soplado, notice: "Registro actualizado.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @soplado.destroy!
    redirect_to soplados_path, notice: "Registro eliminado.", status: :see_other
  end

  private

  def use_chilean_time(&action)
    Time.use_zone(Soplado::ZONE, &action)
  end

  def local_midnight(value, next_day: false)
    date = Date.iso8601(value)
    date = date.next_day if next_day
    Time.zone.local(date.year, date.month, date.day)
  end

  def set_soplado
    @soplado = Soplado.find(params.expect(:id))
  end

  def require_soplado_admin!
    head :forbidden unless task_admin?
  end

  def soplado_params
    attributes = params.expect(soplado: Soplado::LABELS.keys)
    Soplado::MEASUREMENTS.each_key do |field|
      attributes[field] = attributes[field].tr(",", ".") if attributes[field].is_a?(String)
    end
    attributes
  end
end
