# app/controllers/monthly_records_controller.rb
class MonthlyRecordsController < ApplicationController
  before_action :set_monthly_record, only: %i[show edit update destroy]

  def index
    # Permite filtrar por mes (YYYY-MM) en la lista
    if params[:month].present?
      # Convertir "YYYY-MM" -> Date (primer día)
      begin
        month_date = Date.strptime(params[:month] + "-01", "%Y-%m-%d")
        @monthly_records = MonthlyRecord.where(period: month_date.beginning_of_month..month_date.end_of_month).ordered
      rescue ArgumentError
        @monthly_records = MonthlyRecord.none
        flash.now[:alert] = "Mes inválido"
      end
    else
      @monthly_records = MonthlyRecord.ordered
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

  # Acepta "YYYY-MM" desde el input type="month" y lo pasa a Date (día 1)
  def safe_params_with_period
    p = monthly_record_params.dup
    if p[:period].present?
      begin
        p[:period] = Date.strptime(p[:period] + "-01", "%Y-%m-%d")
      rescue ArgumentError
        p[:period] = nil
      end
    end
    p
  end

  def monthly_record_params
    params.require(:monthly_record).permit(
      :period,
      :nomina, :hh, :dp, :actp, :astp, :iap,
      :acreditacion, :salud, :recepcion, :tiempo,
      :soplado, :uso_jetin, :servicios, :despacho
    )
  end
end
