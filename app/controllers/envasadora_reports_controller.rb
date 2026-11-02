class EnvasadoraReportsController < ApplicationController
  before_action :set_report, only: [ :show, :edit, :update, :send_email ]
  before_action :protect_historical_report, only: [ :edit, :update, :send_email ]

  def index
    scope = EnvasadoraReport.all
    scope = scope.where("date >= ?", Date.iso8601(params[:from])) if params[:from].present? && params[:to].blank?
    if params[:from].present? && params[:to].present?
      scope = scope.where(date: Date.iso8601(params[:from])..Date.iso8601(params[:to]))
    elsif params[:to].present?
      scope = scope.where("date <= ?", Date.iso8601(params[:to]))
    end
    scope = scope.where(turno: params[:turno]) if EnvasadoraReport::SHIFTS.key?(params[:turno])
    @pagy, @reports = pagy(scope.order(date: :desc, created_at: :desc, id: :desc), limit: 50)
  rescue Date::Error
    redirect_to envasadora_reports_path, alert: "Usa fechas válidas para consultar el histórico."
  end

  def new
    @report = EnvasadoraReport.new(blank_numeric_attributes.merge(date: Time.current.in_time_zone("America/Santiago").to_date))
  end

  def create
    @report = EnvasadoraReport.new(blank_numeric_attributes.merge(params.require(:envasadora_report).permit(*EnvasadoraReport::INPUT_FIELDS).to_h))
    @report.author_email = current_user[:email]
    if @report.save
      redirect_to @report, notice: "Reporte guardado. Revisa los totales y envía el correo."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show; end

  def edit
    return redirect_to @report, alert: "Solo el autor puede editar un reporte pendiente de envío." unless editable?

    render :new
  end

  def update
    @report.with_lock do
      return redirect_to @report, alert: "Solo el autor puede editar un reporte pendiente de envío." unless editable?

      if @report.update(params.require(:envasadora_report).permit(*EnvasadoraReport::INPUT_FIELDS))
        redirect_to @report, notice: "Reporte actualizado. Revisa los totales antes de enviar."
      else
        render :new, status: :unprocessable_entity
      end
    end
  end

  def send_email
    return redirect_to @report, alert: "Solo el autor puede enviar este reporte." unless @report.author_email == current_user[:email]

    audience = params.fetch(:audience, "normal")
    return redirect_to @report, alert: "Selecciona un envío normal o interno." unless %w[normal internal].include?(audience)

    @report.with_lock do
      unless @report.sent_at?
        EnvasadoraReportMailer.report(@report, internal: audience == "internal").deliver_now
        @report.update!(sent_at: Time.current)
      end
    end
    redirect_to @report, notice: audience == "internal" ? "Reporte enviado a los 3 destinatarios internos." : "Reporte envasadora enviado a la lista completa."
  rescue StandardError => error
    Rails.logger.error("Envasadora report delivery failed: #{error.class}")
    redirect_to @report, alert: "No se pudo confirmar el envío. El reporte sigue guardado; verifica la recepción antes de reintentar."
  end

  private

  def blank_numeric_attributes
    EnvasadoraReport::REQUIRED_NUMERIC_FIELDS.index_with(nil)
  end

  def protect_historical_report
    return unless @report.historical?

    redirect_to @report, alert: "Este reporte es un histórico importado. Se conserva el original y no se edita ni se envía por correo."
  end

  def editable?
    @report.author_email == current_user[:email] && !@report.sent_at?
  end

  def set_report
    @report = EnvasadoraReport.find(params[:id])
  end
end
