class AprWeeklyReport
  attr_reader :start_date, :end_date, :activities

  def initialize(start_date)
    @start_date = start_date
    @end_date = start_date + 6.days
    @activities = AprActivity.joins(:apr_day).includes(:apr_day)
      .where(apr_days: { date: start_date..end_date })
      .order("apr_days.plant", "apr_days.date", :id).to_a
  end

  def total_minutes
    activities.sum(&:duration_minutes)
  end

  def serious_count
    activities.count { |record| record.severity == "grave" }
  end

  def by_plant
    activities.group_by { |record| record.apr_day.plant }
  end

  def pending
    activities.select(&:open_follow_up?).sort_by do |record|
      [ record.severity == "grave" ? 0 : 1, record.due_on, record.id ]
    end
  end
end
