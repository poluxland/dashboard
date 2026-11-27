class AprDaysController < AprController
  before_action :set_owned_day, only: %i[close send_email]

  def show
    @day = visible_days.find(params[:id])
    @activities = @day.activities.order(:id)
    @recipients = @day.closed_at? ? @day.recipients : @day.recipients_for_close
  end

  def close
    current_apr.with_lock do
      @day.reload
      @day.close!(current_apr.email) unless @day.closed_at?
    end
    send_email
  rescue ActiveRecord::RecordInvalid => error
    redirect_to @day, alert: error.record.errors.full_messages.to_sentence, status: :see_other
  end

  def send_email
    unless @day.closed_at?
      return redirect_to @day, alert: "Cierra el día antes de enviar el correo.", status: :see_other
    end

    delivered = @day.with_lock do
      next true if @day.sent_at?
      next false unless deliver_summary

      @day.update!(sent_at: Time.current)
    end
    if delivered
      redirect_to @day, notice: "Cierre registrado y resumen enviado.", status: :see_other
    else
      redirect_to @day, alert: "El día quedó cerrado. Verifica si llegó el correo y, si hace falta, reintenta el envío.", status: :see_other
    end
  end

  private

  def set_owned_day
    @day = owned_days.find(params[:id])
  end

  def deliver_summary
    AprDayMailer.summary(@day).deliver_now
    true
  rescue StandardError => error
    Rails.logger.error("APR activity summary delivery failed: #{error.class}")
    false
  end
end
