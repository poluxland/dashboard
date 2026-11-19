class OperationActivitiesController < ApplicationController
  before_action :set_activity, only: %i[edit update]

  def index
    week_of = OperationWeeklyReport.previous_week
    if params[:semana].present?
      begin
        date = params[:semana].to_s
        raise Date::Error unless date.match?(/\A[1-9]\d{3}-\d{2}-\d{2}\z/)

        week_of = Date.iso8601(date)
      rescue Date::Error
        flash.now[:alert] = "Selecciona una fecha válida para consultar la semana."
      end
    end
    @report = OperationWeeklyReport.new(week_of: week_of)
  end

  def new
    @activity = OperationActivity.new(fecha: OperationWeeklyReport.local_today)
  end

  def create
    @activity = OperationActivity.new(activity_params)
    if @activity.save
      redirect_to operation_activities_path(semana: @activity.fecha.iso8601), notice: "Actividad registrada.", status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @activity.update(activity_params)
      redirect_to operation_activities_path(semana: @activity.fecha.iso8601), notice: "Actividad actualizada.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_activity
    @activity = OperationActivity.find(params.expect(:id))
  end

  def activity_params
    params.expect(operation_activity: %i[fecha area actividad tipo estado])
  end
end
