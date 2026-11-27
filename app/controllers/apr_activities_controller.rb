class AprActivitiesController < AprController
  before_action :set_owned_activity, only: %i[edit update follow_up]

  def index
    @date = apr_date(params[:date]) || AprDay.today
    @plant = selected_plant
    @day = owned_days.find_by(date: @date, plant: @plant)
    @reported_days = visible_days.where(date: @date, plant: @plant)
      .where.not(apr: current_apr).where.not(closed_at: nil).order(:closed_by_email)
    scope = AprActivity.where(apr_day: @day)
    @day_minutes = scope.sum(:duration_minutes)
    @day_count = scope.count
    @activities = filtered_activities(scope).order(:id)
    @filtered = @filters.any? || @query.present?
  end

  def show
    @activity = AprActivity.where(apr_day: visible_days).find(params[:id])
  end

  def follow_ups
    @status = params[:status].presence_in(%w[open pending in_progress closed all]) || "open"
    @plant = params[:plant].presence_in(AprDay::PLANTS.keys)
    days = @plant ? visible_days.where(plant: @plant) : visible_days
    scope = AprActivity.where(apr_day: days).follow_ups
    scope = scope.open_follow_ups if @status == "open"
    scope = scope.where(follow_up_status: @status) unless @status.in?(%w[open all])
    @pagy, @activities = pagy(filtered_activities(scope).includes(:apr_day)
      .order(Arel.sql("CASE WHEN apr_activities.severity = 'grave' THEN 0 ELSE 1 END"), :due_on, :id),
      limit: 30, overflow: :last_page)
  end

  def new
    @date = apr_date(params[:date]) || AprDay.today
    @plant = selected_plant
    @activity = AprActivity.new(outcome: "none")
  end

  def create
    @activity = AprActivity.new

    if save_activity
      destination = if params[:commit_action] == "add_another"
        new_apr_activity_path(date: @date, plant: @plant)
      else
        apr_activities_path(date: @date, plant: @plant)
      end
      redirect_to destination, notice: "Actividad registrada.", status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @date = @activity.apr_day.date
    @plant = @activity.apr_day.plant
    return unless @activity.apr_day.closed_at?

    redirect_to @activity, alert: "El día ya está cerrado. Puedes actualizar el seguimiento en el detalle."
  end

  def update
    if save_activity
      redirect_to @activity, notice: "Actividad actualizada.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def follow_up
    saved = current_apr.with_lock do
      @activity.reload
      next false unless @activity.open_follow_up?

      case params[:status]
      when "in_progress"
        @activity.update(follow_up_status: "in_progress")
      when "closed"
        @activity.update(follow_up_status: "closed", resolution: params.permit(:resolution)[:resolution],
          resolved_at: Time.current, resolved_by_email: current_apr.email)
      else
        false
      end
    end
    if saved
      redirect_to @activity, notice: "Seguimiento actualizado.", status: :see_other
    else
      flash.now[:alert] = "Elige un estado válido e indica la solución al cerrar el seguimiento." if @activity.errors.empty?
      @activity.restore_attributes(%w[follow_up_status resolved_at resolved_by_email])
      render :show, status: :unprocessable_entity
    end
  end

  private

  def selected_plant
    plant = params[:plant].presence_in(AprDay::PLANTS.keys)
    session[:apr_activity_plant] = plant if plant
    session[:apr_activity_plant].presence_in(AprDay::PLANTS.keys) || "PTM"
  end

  def set_owned_activity
    @activity = AprActivity.where(apr_day: owned_days).find(params[:id])
  end

  def activity_params
    @activity_params ||= params.expect(apr_activity: %i[
      date plant sector activity_type title observations duration_hours duration_remainder outcome severity responsible due_on
    ])
  end

  def save_activity
    @date = apr_date(activity_params[:date])
    @plant = activity_params[:plant].presence_in(AprDay::PLANTS.keys)
    attributes = activity_params.except(:date, :plant)
    @activity.errors.add(:base, "Ingresa una fecha válida que no sea posterior a hoy.") unless @date
    @activity.errors.add(:base, "Selecciona una planta válida.") unless @plant
    if @activity.errors.any?
      @activity.assign_attributes(attributes)
      return false
    end

    current_apr.with_lock do
      @activity.reload if @activity.persisted?
      original_day = @activity.apr_day
      @activity.assign_attributes(attributes)
      day = owned_days.find_or_initialize_by(date: @date, plant: @plant)
      if original_day&.closed_at? || day.closed_at?
        @activity.errors.add(:base, "El día ya está cerrado.")
        next false
      end

      @activity.apr_day = day
      @activity.save
    end
  end

  def filtered_activities(scope)
    @filters = {
      sector: params[:sector].presence_in(AprActivity::SECTORS),
      activity_type: params[:activity_type].presence_in(AprActivity::ACTIVITY_TYPES)
    }.compact
    scope = scope.where(@filters)
    @query = params.permit(:q)[:q].to_s.strip.first(120)
    if @query.present?
      pattern = "%#{AprActivity.sanitize_sql_like(@query)}%"
      scope = scope.where("title ILIKE :pattern OR observations ILIKE :pattern", pattern: pattern)
    end
    scope
  end
end
