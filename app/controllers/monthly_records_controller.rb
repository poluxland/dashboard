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

  # 👉 Tu view usa @chart_labels / @chart_datasets. Alimentémoslos con SOLO:
  # Recepción, Tiempo, Soplado, Uso Jetin, Servicios, Despacho
  @chart_labels, @chart_datasets = MonthlyRecord.chart_data(
    @monthly_records,
    only: %i[recepcion tiempo soplado uso_jetin servicios despacho]
  )

  # Si no ocupas estos otros, puedes borrarlos:
  # @core_labels, @core_datasets = ...
  # @recepcion_labels, recepcion_datasets = ...
  # @recepcion_dataset = recepcion_datasets.first

  if params[:month].present? && (r = @monthly_records.first)
    @breakdown = MonthlyRecord::METRICS
      .index_with { |m| r.public_send(m) }
      .transform_keys { |k| k.to_s.humanize }
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
