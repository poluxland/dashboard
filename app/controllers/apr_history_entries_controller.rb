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
    return unless params[:position]

    @position = Integer(params[:position].to_s, 10, exception: false)
    raise ActiveRecord::RecordNotFound unless @position&.between?(1, @entry.activities.size)
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
        activity_item.text ILIKE :pattern
        OR (cardinality(activities) = 1 AND observations ILIKE :pattern)
        OR day_status ILIKE :pattern
        OR EXISTS (
          SELECT 1 FROM jsonb_each_text(activity_details -> activity_item.position::text) AS field
          WHERE field.key IN ('type', 'sector', 'observations', 'outcome', 'severity', 'responsible', 'due_on', 'duration_minutes')
            AND field.value ILIKE :pattern
        )
      SQL
    end
    scope
  end

  def require_history_access!
    head :forbidden unless apr_history_access?
  end
end
