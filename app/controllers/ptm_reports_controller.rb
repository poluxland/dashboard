class PtmReportsController < ApplicationController
  helper EnvasadoraDashboardHelper
  before_action :set_report, only: [ :edit, :update ]

  def index
    @dashboard = PtmDashboard.new(params[:period])
  end

  def new
    @report = PtmReport.new(date: Date.current)
    @report.ptm_events.build
  end

  def create
    @report = PtmReport.new(report_params)
    @report.author_email = current_user[:email]
    if @report.save
      redirect_to ptm_reports_path(period: "month"), notice: "Turno PTM guardado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    render :new
  end

  def update
    if @report.update(report_params)
      redirect_to ptm_reports_path(period: "all"), notice: "Turno PTM actualizado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_report
    @report = PtmReport.find(params[:id])
    if @report.source_key.present? || @report.author_email != current_user[:email]
      redirect_to ptm_reports_path, alert: "Solo puedes editar los turnos que registraste en la aplicación."
    end
  end

  def report_params
    params.require(:ptm_report).permit(:date, :shift, :production,
      ptm_events_attributes: [ :id, :equipment, :reason, :minutes, :equipment_state, :_destroy ])
  end
end
