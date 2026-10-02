class ShiftReportsController < ApplicationController
  before_action :set_report, only: [ :show, :send_email ]

  def index
    @reports = ShiftReport.order(created_at: :desc).limit(100)
  end

  def new
    @report = ShiftReport.new(date: Time.current.in_time_zone("America/Santiago").to_date)
    load_people
  end

  def create
    @report = ShiftReport.new(params.require(:shift_report).permit(:date, :shift, :confirmed, person_ids: []))
    ids = Array(@report.person_ids).reject(&:blank?).uniq
    people = Person.where(id: ids).order(:name).to_a
    @report.assign_attributes(
      signer_name: current_user[:name].presence || current_user[:email],
      signer_email: current_user[:email], statement: ShiftReport::STATEMENT,
      participants: people.map { |person| { id: person.id, name: person.name, area: person.area, planta: person.planta } }
    )
    @report.valid?
    @report.errors.add(:base, "La nómina cambió. Revisa las personas seleccionadas.") if people.size != ids.size
    if @report.errors.empty? && @report.save
      redirect_to @report, notice: "Informe generado. Revisa el contenido y envíalo a los destinatarios."
    else
      load_people
      render :new, status: :unprocessable_entity
    end
  end

  def show; end

  def send_email
    unless @report.signer_email == current_user[:email]
      return redirect_to @report, alert: "Solo quien firmó el informe puede enviarlo."
    end

    @report.with_lock do
      unless @report.sent_at?
        ShiftReportMailer.closing_report(@report).deliver_now
        @report.update!(sent_at: Time.current)
      end
    end
    redirect_to @report, notice: "Informe enviado a los tres destinatarios."
  rescue StandardError => error
    Rails.logger.error("Shift report delivery failed: #{error.class}")
    redirect_to @report, alert: "No se pudo confirmar el envío. El informe sigue guardado; verifica la recepción antes de reintentar."
  end

  private

  def set_report
    @report = ShiftReport.find(params[:id])
  end

  def load_people
    @people = Person.order(:name)
    @areas = @people.map(&:area).compact_blank.uniq.sort
  end
end
