class SessionsController < ApplicationController
  skip_before_action :authenticate_user!

  def new
    return redirect_to root_path if signed_in?

    @google_oauth_configured = Rails.application.config.x.google_oauth_configured
  end

  def create
    auth = request.env["omniauth.auth"]

    unless authorized_workspace_account?(auth)
      reset_session
      redirect_to login_path, alert: "Acceso permitido solo para cuentas de @#{workspace_domain}."
      return
    end

    return_to = safe_return_to
    reset_session
    session[:user] = {
      uid: auth.uid,
      email: auth.info.email,
      name: auth.info.name.presence || auth.info.email,
      authenticated_at: Time.current.to_i
    }

    redirect_to(return_to, notice: "Sesión iniciada correctamente.")
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Sesión cerrada correctamente."
  end

  def failure
    redirect_to login_path, alert: "No se pudo iniciar sesión con Google. Inténtalo nuevamente."
  end

  private

  def authorized_workspace_account?(auth)
    return false if auth.blank? || auth.provider != "google_oauth2" || auth.uid.blank?

    claims = auth.dig("extra", "id_info").presence || auth.dig("extra", "raw_info") || {}
    hosted_domain = claims["hd"].to_s.downcase
    email_verified = ActiveModel::Type::Boolean.new.cast(
      auth.dig("info", "email_verified") || claims["email_verified"]
    )

    hosted_domain == workspace_domain && email_verified && auth.info.email.present?
  end

  def workspace_domain
    Rails.application.config.x.google_workspace_domain
  end

  def safe_return_to
    path = session.delete(:return_to).to_s
    return path if path.start_with?("/") && !path.start_with?("//")

    root_path
  end
end
