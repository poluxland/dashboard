class TptImportsController < ApplicationController
  def index
    load_dashboard
  end

  def create
    upload = params[:archivo]
    raise TptExcelImporter::InvalidSpreadsheet, "Selecciona un archivo XLSX de hasta 10 MB." unless
      upload.respond_to?(:original_filename) && upload.original_filename.downcase.end_with?(".xlsx") && upload.size <= 10.megabytes

    report = TptExcelImporter.new(upload, author_email: current_user[:email]).call
    redirect_to tpt_import_path(report), notice: "Carga terminada: #{report.imported_count} eventos nuevos, #{report.duplicate_count} duplicados y #{report.issues.size} filas para revisar."
  rescue TptExcelImporter::InvalidSpreadsheet => error
    flash.now[:alert] = error.message
    load_dashboard
    render :index, status: :unprocessable_entity
  end

  def show
    @report = TptImport.find(params[:id])
    @pagy, @events = pagy(@report.tpt_events.order(started_at: :desc, id: :desc), limit: 100)
  end

  private

  def load_dashboard
    @imports = TptImport.order(created_at: :desc, id: :desc).limit(30)
    @event_count = TptEvent.count
    @negative_count = TptEvent.where("duration_seconds < 0").count
    @hours_by_impact = TptEvent.nonnegative.group(:impact).sum(:duration_seconds)
  end
end
