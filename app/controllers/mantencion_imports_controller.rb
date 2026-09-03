class MantencionImportsController < ApplicationController
  MAX_FILE_SIZE = 10.megabytes

  before_action :require_demo_user!

  def new
  end

  def create
    archivo = params[:archivo]

    return render_error("Selecciona un archivo XLSX.") if archivo.blank?
    return render_error("Solo se permiten archivos con extensión .xlsx.") unless archivo.original_filename.to_s.downcase.end_with?(".xlsx")
    return render_error("El archivo supera el máximo permitido de 10 MB.") if archivo.size > MAX_FILE_SIZE
    return render_error("Debes confirmar la importación.") unless params[:confirmar] == "1"

    @result = MantencionExcelImporter.new(archivo).call
    @filename = archivo.original_filename
    render :new
  rescue MantencionExcelImporter::InvalidSpreadsheet => error
    render_error(error.message)
  end

  private

  def render_error(message)
    flash.now[:alert] = message
    render :new, status: :unprocessable_entity
  end
end
