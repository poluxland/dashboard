class AprController < ApplicationController
  before_action :protect_apr_responses
  helper_method :apr_day_owner?

  private

  def protect_apr_responses
    response.headers["Cache-Control"] = "no-store"
  end

  def current_apr
    @current_apr ||= DashboardUser.find_by!(email: RecordAuthor.email)
  end

  def owned_days
    AprDay.where(apr: current_apr)
  end

  def visible_days
    return AprDay.all if task_admin?

    owned_days.or(AprDay.where("? = ANY(apr_days.recipients)", current_apr.email))
  end

  def apr_day_owner?(day)
    day.apr_id == current_apr.id
  end

  def apr_date(value)
    return unless value.is_a?(String) && value.match?(/\A[1-9]\d{3}-\d{2}-\d{2}\z/)

    date = Date.iso8601(value)
    date if date <= AprDay.today
  rescue Date::Error
    nil
  end
end
