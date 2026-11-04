class PublicWorkReportsController < ApplicationController
  skip_before_action :authenticate_user!, only: :show
  layout "public_report"

  def show
    response.headers["Cache-Control"] = "no-store"
    response.headers["X-Robots-Tag"] = "noindex, nofollow, noarchive"
    response.headers["Referrer-Policy"] = "no-referrer"
    return head :not_acceptable unless request.format.html?

    @work = Work.find_signed!(params[:token], purpose: :shared_work_report)
    render formats: [ :html ]
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    raise ActiveRecord::RecordNotFound
  end
end
