class OperationActivityMailer < ApplicationMailer
  def weekly_report(recipients:, week_of: OperationWeeklyReport.previous_week)
    @report = OperationWeeklyReport.new(week_of: week_of)
    mail(to: recipients, subject: @report.title)
  end
end
