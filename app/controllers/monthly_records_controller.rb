class MonthlyRecordsController < ApplicationController
  before_action :set_monthly_record, only: %i[show edit update destroy]

def index
  if params[:month].present?
    begin
      month_date = Date.strptime("#{params[:month]}-01", "%Y-%m-%d")
      @monthly_records = MonthlyRecord.where(
        period: month_date.beginning_of_month..month_date.end_of_month
      ).ordered
    rescue ArgumentError
      @monthly_records = MonthlyRecord.none
      flash.now[:alert] = "Mes inválido"
    end
  else
    @monthly_records = MonthlyRecord.ordered
    # Si prefieres limitar por defecto:
    # @monthly_records = MonthlyRecord.last_12_months.ordered
  end



  # Gráfico general (todos los parámetros)
  @chart_labels, @chart_datasets = MonthlyRecord.chart_data(@monthly_records)

  # >>> Gráfico solo DP, ACTP, ASTP, IAP <<<
  @core_labels, @core_datasets = MonthlyRecord.chart_data(
    @monthly_records,
    only: %i[dp actp astp iap]
  )

  # Donut del mes filtrado (si aplica)
  if params[:month].present? && (r = @monthly_records.first)
    @breakdown = MonthlyRecord::METRICS
      .index_with { |m| r.public_send(m) }
      .transform_keys { |k| k.to_s.humanize }
  end

# Gráfico de barras solo Recepción
@recepcion_labels, recepcion_datasets = MonthlyRecord.chart_data(
  @monthly_records,
  only: %i[recepcion]
)
# Chart.js espera un array, así que tomo el primero
@recepcion_dataset = recepcion_datasets.first
end


  def show; end

  def new
    @monthly_record = MonthlyRecord.new
  end

  def edit; end

  def create
    @monthly_record = MonthlyRecord.new(safe_params_with_period)
    if @monthly_record.save
      redirect_to @monthly_record, notice: "Registro mensual creado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @monthly_record.update(safe_params_with_period)
      redirect_to @monthly_record, notice: "Registro mensual actualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @monthly_record.destroy
    redirect_to monthly_records_url, notice: "Registro mensual eliminado."
  end

  private

  def set_monthly_record
    @monthly_record = MonthlyRecord.find(params[:id])
  end

  # Acepta "YYYY-MM" desde el input type="month" y lo pasa a Date (día 1)
  def safe_params_with_period
    p = monthly_record_params.dup
    if p[:period].present?
      begin
        p[:period] = Date.strptime("#{p[:period]}-01", "%Y-%m-%d")
      rescue ArgumentError
        p[:period] = nil
      end
    end
    p
  end

  def monthly_record_params
    params.require(:monthly_record).permit(
      :period, *MonthlyRecord::METRICS
    )
  end
end
