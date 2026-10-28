class EnvasadoraReportsController < ApplicationController
  before_action :set_report, only: [ :show, :edit, :update, :send_email ]

  def index
    @reports = EnvasadoraReport.order(date: :desc, created_at: :desc).limit(100)
  end

  def new
    @report = EnvasadoraReport.new(date: Time.current.in_time_zone("America/Santiago").to_date)
  end

  def create
    @report = EnvasadoraReport.new(params.require(:envasadora_report).permit(*EnvasadoraReport::INPUT_FIELDS))
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

    @report.with_lock do
      unless @report.sent_at?
        EnvasadoraReportMailer.report(@report).deliver_now
        @report.update!(sent_at: Time.current)
      end
    end
    redirect_to @report, notice: "Reporte envasadora enviado."
  rescue StandardError => error
    Rails.logger.error("Envasadora report delivery failed: #{error.class}")
    redirect_to @report, alert: "No se pudo confirmar el envío. El reporte sigue guardado; verifica la recepción antes de reintentar."
  end

  private

  def editable?
    @report.author_email == current_user[:email] && !@report.sent_at?
  end

  def set_report
    @report = EnvasadoraReport.find(params[:id])
  end
end
