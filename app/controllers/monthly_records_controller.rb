# app/controllers/monthly_records_controller.rb
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
    end

    # Gráfico de líneas (Nómina, HH, DP, ACTP, ASTP, IAP, Acreditación, Salud)
    @chart_labels, @chart_datasets = MonthlyRecord.chart_data(
      @monthly_records,
      only: %i[nomina hh dp actp astp iap acreditacion salud]
    )

    # Gráfico stacked (Recepción, Tiempo, Soplado, Uso Jetin, Servicios, Despacho)
    @stacked_labels, @stacked_datasets = MonthlyRecord.chart_data(
      @monthly_records,
      only: %i[recepcion tiempo soplado uso_jetin servicios despacho]
    )

    @all_labels, @all_datasets = MonthlyRecord.chart_data(
  @monthly_records,
  only: MonthlyRecord::METRICS  # => todos los campos (asegúrate de que METRICS incluya todos)
)

    # Donut (si filtras por month)
    if params[:month].present? && (r = @monthly_records.first)
      @breakdown = MonthlyRecord::METRICS
        .index_with { |m| r.public_send(m) }
        .transform_keys { |k| k.to_s.humanize }
    end
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

  # Acepta "YYYY-MM" desde input type="month" y lo transforma a Date (día 1)
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
    params.require(:monthly_record).permit(:period, *MonthlyRecord::METRICS)
  end
end
