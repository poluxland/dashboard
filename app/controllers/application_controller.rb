class ApplicationController < ActionController::Base
  SESSION_DURATION = 12.hours
  DEMO_USER_EMAIL = "jose.jerez@msindustrial.cl"

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  include Pagy::Backend

  before_action :authenticate_user!

  helper_method :current_user, :signed_in?, :demo_user?

  private

  def current_user
    user = session[:user]
    return if user.blank?

    user.with_indifferent_access
  end

  def signed_in?
    authenticated_at = current_user&.fetch(:authenticated_at, 0).to_i
    current_user.present? && authenticated_at >= SESSION_DURATION.ago.to_i
  end

  def demo_user?
    signed_in? && current_user[:email].to_s.casecmp?(DEMO_USER_EMAIL)
  end

  def authenticate_user!
    return if signed_in?

    return_to = request.fullpath if request.get? && request.format.html?
    reset_session
    session[:return_to] = return_to if return_to.present?
    redirect_to login_path, alert: "Debes iniciar sesión con tu cuenta corporativa."
  end

  def require_demo_user!
    return if demo_user?

    redirect_to root_path, alert: "No tienes permisos para acceder a Demo."
  end
end
