class PmmTrucksController < ApplicationController
  EXPORT_LIMIT = 5000
  skip_before_action :authenticate_user!, only: %i[index month]
  before_action :set_truck, only: %i[show edit update destroy]
  before_action :require_truck_admin!, only: :destroy

  def index
    respond_to do |format|
      format.html do
        @on_site = PmmTruck.on_site(today).includes(:pmm_material).order(:llegada, :id)
        @trucks = PmmTruck.includes(:pmm_material).order(created_at: :desc, id: :desc).limit(15)
      end
      format.xlsx { export(PmmTruck.order(created_at: :desc, id: :desc).limit(EXPORT_LIMIT)) }
    end
  end

  def month
    @title = "Camiones del mes"
    @pagy, @trucks = pagy(PmmTruck.includes(:pmm_material).where(fecha: today.all_month).order(fecha: :desc, id: :desc), limit: 40)
  end

  def history
    @filters = params.permit(:from, :to, :patente, :pmm_material_id, :tipo, :period)
    @materials = PmmMaterial.order(:nombre)
    scope = filtered_history
    respond_to do |format|
      format.html { @pagy, @trucks = pagy(scope.includes(:pmm_material), limit: 50) }
      format.xlsx do
        if scope.limit(EXPORT_LIMIT + 1).count > EXPORT_LIMIT
          redirect_to history_pmm_trucks_path(@filters), alert: "Acota las fechas para descargar hasta 5.000 registros por archivo."
        else
          export(scope)
        end
      end
    end
  rescue Date::Error
    redirect_to history_pmm_trucks_path, alert: "Usa fechas válidas para consultar el histórico."
  end

  def report
    date = params[:date].presence ? Date.iso8601(params[:date]) : today
    @report = PmmTruckReport.new(date)
  rescue Date::Error, TypeError
    redirect_to report_pmm_trucks_path, alert: "Usa una fecha válida para el reporte."
  end

  def annual
    @reports = PmmTruckReport.new(today)
    @years = @reports.years
    @year = Integer(params[:year].to_s, 10, exception: false).presence_in(@years) || @years.first
    @annual = @reports.annual(@year)
  end

  def show; end

  def new
    @truck = PmmTruck.new(fecha: today)
    prepare_form
  end

  def create
    @truck = PmmTruck.new(truck_params)
    if @truck.save(context: :capture)
      redirect_to pmm_truck_path(@truck), notice: "Camión registrado.", status: :see_other
    else
      prepare_form
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    prepare_form
  end

  def update
    @truck.with_lock do
      @truck.assign_attributes(truck_params)
      if @truck.save(context: :capture)
        redirect_to pmm_truck_path(@truck), notice: "Registro actualizado.", status: :see_other
      else
        prepare_form
        render :edit, status: :unprocessable_entity
      end
    end
  end

  def destroy
    @truck.destroy!
    redirect_to history_pmm_trucks_path, notice: "Registro eliminado.", status: :see_other
  end

  private

  def today
    Time.current.in_time_zone(PmmTruck::CHILE).to_date
  end

  def filtered_history
    scope = PmmTruck.order(fecha: :desc, id: :desc)
    scope = scope.where(fecha: today.all_year) if @filters[:period] == "year"
    scope = scope.where(fecha: Date.iso8601(@filters[:from])..) if @filters[:from].present?
    scope = scope.where(fecha: ..Date.iso8601(@filters[:to])) if @filters[:to].present?
    scope = scope.where(pmm_material_id: @filters[:pmm_material_id]) if @filters[:pmm_material_id].present?
    scope = scope.where(tipo: @filters[:tipo]) if @filters[:tipo].present?
    if @filters[:patente].present?
      pattern = "%#{PmmTruck.sanitize_sql_like(@filters[:patente].strip)}%"
      scope = scope.where("patente ILIKE ?", pattern)
    end
    scope
  end

  def export(scope)
    @export_trucks = scope.includes(:pmm_material)
    response.headers["Content-Disposition"] = 'attachment; filename="camiones-la-calera.xlsx"'
    render :export
  end

  def prepare_form
    @materials = PmmMaterial.order(:nombre)
  end

  def set_truck
    @truck = PmmTruck.find(params.expect(:id))
  end

  def truck_params
    params.expect(pmm_truck: PmmTruck::INPUTS)
  end

  def require_truck_admin!
    head :forbidden unless task_admin?
  end
end
