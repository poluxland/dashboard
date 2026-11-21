class OvertimeEntriesController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :require_overtime_access
  before_action :require_staff, only: %i[new create edit update]

  def index
    entries = OvertimeAccess.entries_for(@reviewer)
    @status = params[:estado].presence || OvertimeEntry::PENDING
    entries = case @status
    when "todos" then entries
    when "sin_estado" then entries.where(estado: [nil, ""])
    when *OvertimeEntry::STATUSES then entries.where(estado: @status)
    else return redirect_to overtime_entries_path, alert: "Elige un estado válido."
    end
    filters = params.permit(:from, :to, :mandante)
    entries = entries.where("fecha >= ?", Date.iso8601(filters[:from])) if filters[:from].present?
    entries = entries.where("fecha <= ?", Date.iso8601(filters[:to])) if filters[:to].present?
    @mandantes = OvertimeAccess.entries_for(@reviewer).where.not(mandante: [nil, ""]).distinct.order(:mandante).pluck(:mandante)
    entries = entries.where(mandante: filters[:mandante]) if filters[:mandante].present?
    @pagy, @entries = pagy(entries.includes(:overtime_reviews).order(Arel.sql("fecha DESC NULLS LAST"), id: :desc), limit: 100)
  rescue Date::Error
    redirect_to overtime_entries_path, alert: "Usa fechas válidas."
  end

  def new
    @entry = OvertimeEntry.new(fecha: Time.current.in_time_zone("America/Santiago").to_date)
  end

  def create
    @entry = OvertimeEntry.new(entry_params.merge(author_email: @reviewer, estado: OvertimeEntry::PENDING))
    if @entry.save(context: :capture)
      redirect_to overtime_entries_path, notice: "Horas extra registradas."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @entry = OvertimeEntry.pending_review.find(params[:id])
  end

  def update
    @entry = OvertimeEntry.pending_review.find(params[:id])
    @entry.with_lock do
      return redirect_to overtime_entries_path, alert: "El registro ya fue revisado." if @entry.estado != OvertimeEntry::PENDING

      @entry.assign_attributes(entry_params)
      if @entry.save(context: :capture)
        redirect_to overtime_entries_path, notice: "Registro actualizado."
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end

  def review
    count = OvertimeBatchReview.call(reviewer: @reviewer, ids: params[:ids], status: params[:decision], reason: params[:reason])
    redirect_to overtime_entries_path, notice: "#{count} #{count == 1 ? 'registro actualizado' : 'registros actualizados'}."
  rescue OvertimeBatchReview::InvalidReview => error
    redirect_to overtime_entries_path, alert: error.message
  end

  private

  def require_overtime_access
    response.headers["Cache-Control"] = "no-store"
    response.headers["X-Robots-Tag"] = "noindex, nofollow"
    if signed_in? && OvertimeAccess.staff?(current_user[:email])
      @reviewer = OvertimeAccess.normalize(current_user[:email])
      @staff = true
    elsif session[:overtime_reviewer].present?
      email = session[:overtime_reviewer]["email"]
      expires_at = session[:overtime_reviewer]["expires_at"].to_i
      @reviewer = email if expires_at > Time.current.to_i && OvertimeAccess.external?(email)
    end
    return if @reviewer

    session[:return_to] = overtime_entries_path if action_name == "index" && !signed_in?
    redirect_to overtime_login_path
  end

  def require_staff
    head :forbidden unless @staff
  end

  def entry_params
    params.require(:overtime_entry).permit(*OvertimeEntry::INPUT_FIELDS)
  end
end
