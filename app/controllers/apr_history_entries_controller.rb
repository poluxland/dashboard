class AprHistoryEntriesController < AprController
  before_action :require_history_access!

  def index
    @plant = params[:plant].presence_in(AprDay::PLANTS.keys)
    @from = apr_date(params[:from])
    @to = apr_date(params[:to])
    @query = params.permit(:q)[:q].to_s.strip.first(120)
    if @from && @to && @from > @to
      flash.now[:alert] = "La fecha inicial debe ser anterior o igual a la fecha final."
      scope = AprHistoryEntry.none
    else
      scope = filtered_history
    end
    order = scope.order(date: :desc, source_row: :desc, id: :desc).order(Arel.sql("activity_item.position"))
    @pagy, @entries = pagy(order, limit: 30, overflow: :last_page)
  end

  def show
    @entry = AprHistoryEntry.find(params[:id])
  end

  private

  def filtered_history
    scope = AprHistoryEntry.with_listed_activities
    scope = scope.where(plant: @plant) if @plant
    scope = scope.where(end_date: @from..) if @from
    scope = scope.where(date: ..@to) if @to
    if @query.present?
      pattern = "%#{AprHistoryEntry.sanitize_sql_like(@query)}%"
      scope = scope.where(<<~SQL, pattern: pattern)
        source_area ILIKE :pattern OR activity_item.text ILIKE :pattern OR observations ILIKE :pattern
        OR day_status ILIKE :pattern
        OR CAST(activity_details -> activity_item.position::text AS text) ILIKE :pattern
      SQL
    end
    scope
  end

  def require_history_access!
    head :forbidden unless apr_history_access?
  end
end
