class TaskMailer < ApplicationMailer
  def notice(notification)
    @task = notification.task
    @reminder = notification.kind == "due"
    @recipient = DashboardUser.find_by(email: notification.recipient)&.name.presence || notification.recipient
    @creator = DashboardUser.find_by(email: @task.creator_email)&.name.presence || @task.creator_email
    @heading = @reminder ? "Tu actividad vence hoy" : "Tienes una nueva actividad asignada"
    mail(to: notification.recipient, subject: "#{@reminder ? 'Vence hoy' : 'Nueva actividad'}: #{@task.title}")
  end
end
