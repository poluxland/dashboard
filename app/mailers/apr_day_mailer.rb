class AprDayMailer < ApplicationMailer
  helper AprActivitiesHelper

  def summary(day)
    @day = day
    @summary = day.email_summary
    @plant = AprDay::PLANTS.fetch(day.plant)
    mail(to: day.recipients, reply_to: day.closed_by_email, subject: "Cierre de actividades APR · #{@plant} · #{day.date.strftime('%d-%m-%Y')}")
  end

  def weekly_summary(report:, recipients:)
    @report = report
    start_date = report.start_date.strftime("%d-%m-%Y")
    end_date = report.end_date.strftime("%d-%m-%Y")
    mail(to: recipients, subject: "Resumen semanal de actividades APR · #{start_date} al #{end_date}")
  end
end
