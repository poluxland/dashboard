class AprDayMailer < ApplicationMailer
  helper AprActivitiesHelper

  def summary(day)
    @day = day
    @summary = day.email_summary
    @plant = AprDay::PLANTS.fetch(day.plant)
    mail(to: day.recipients, reply_to: day.closed_by_email, subject: "Cierre de actividades APR · #{@plant} · #{day.date.strftime('%d-%m-%Y')}")
  end
end
