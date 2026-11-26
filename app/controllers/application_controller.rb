class ApplicationController < ActionController::Base
  SESSION_DURATION = 12.hours
  DEMO_USER_EMAILS = %w[
    jose.jerez@msindustrial.cl
    fernando.gonzalez@msindustrial.cl
  ].freeze
  TRABAJOS_SUMMARY_USER_EMAILS = %w[
    administracion@msindustrial.cl
    elizabeth.zuniga@msindustrial.cl
    fernando.gonzalez@msindustrial.cl
    jose.jerez@msindustrial.cl
    julio.alvear@msindustrial.cl
    orlando.lobos@msindustrial.cl
    simon.rojas@msindustrial.cl
    susana.molina@msindustrial.cl
  ].freeze
  TRABAJOS_USER_EMAILS = (TRABAJOS_SUMMARY_USER_EMAILS + %w[claudio.gutierrez@msindustrial.cl]).freeze

  allow_browser versions: { ie: false }
  include Pagy::Backend

  around_action :track_record_author
  before_action :authenticate_user!

  helper_method :current_user, :signed_in?, :demo_user?, :task_admin?, :trabajos_access?

  private

  def track_record_author(&action)
    email = current_user[:email].to_s.strip.downcase.presence if signed_in?
    RecordAuthor.set(tracking: true, email: email, &action)
  end

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
    signed_in? && DEMO_USER_EMAILS.any? { |email| current_user[:email].to_s.casecmp?(email) }
  end

  def task_admin?
    demo_user?
  end

  def trabajos_access?
    signed_in? && TRABAJOS_USER_EMAILS.include?(current_user[:email].to_s.strip.downcase)
  end

  def trabajos_summary_access?
    signed_in? && TRABAJOS_SUMMARY_USER_EMAILS.include?(current_user[:email].to_s.strip.downcase)
  end

  def authenticate_user!
    if signed_in?
      DashboardUser.record_login(current_user) unless DashboardUser.exists?(email: current_user[:email].to_s.strip.downcase)
      return
    end

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
