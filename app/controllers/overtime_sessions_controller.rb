class OvertimeSessionsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :prevent_caching
  rate_limit to: 8, within: 5.minutes, only: :request_code
  rate_limit to: 20, within: 5.minutes, only: :verify

  def new
    @code_requested = session[:overtime_challenge].present?
  end

  def request_code
    email = OvertimeAccess.normalize(params[:email]).first(254)
    unless session[:overtime_challenge].present? && session[:overtime_challenge]["email"] == email
      session[:overtime_challenge] = { "email" => email }
    end
    issued = OvertimeLoginCode.issue(email)
    if issued
      challenge, code = issued
      session[:overtime_challenge]["id"] = challenge
      OvertimeMailer.login_code(email: email, code: code).deliver_now
    end
    redirect_to overtime_login_path, notice: "Si el correo está autorizado para revisión, recibirás un código."
  rescue Net::SMTPError, Timeout::Error, IOError, SocketError, SystemCallError => error
    Rails.logger.error("Overtime code mail failed: #{error.class}")
    redirect_to overtime_login_path, alert: "No se pudo completar la solicitud. Inténtalo en un minuto."
  end

  def verify
    pending = session[:overtime_challenge] || {}
    email = pending["email"]
    valid = OvertimeLoginCode.consume(email: email, challenge: pending["id"], code: params[:overtime_code].to_s.strip)
    unless valid
      return redirect_to overtime_login_path, alert: "El código es incorrecto o expiró. Puedes solicitar uno nuevo."
    end

    reset_session
    session[:overtime_reviewer] = { "email" => email, "expires_at" => 2.hours.from_now.to_i }
    redirect_to overtime_entries_path, notice: "Ya puedes revisar tus horas pendientes."
  end

  def destroy
    session.delete(:overtime_reviewer)
    session.delete(:overtime_challenge)
    redirect_to overtime_login_path, notice: "Sesión de revisión cerrada."
  end

  private

  def prevent_caching
    response.headers["Cache-Control"] = "no-store"
    response.headers["X-Robots-Tag"] = "noindex, nofollow"
  end
end
