class HomeController < ApplicationController
  def index
    today = Time.current.in_time_zone("America/Santiago").to_date
    tasks = Task.where(assignee_email: current_user[:email].to_s.downcase).ordered.to_a
    pending = tasks.reject { |task| task.status == "done" }
    @task_groups = {
      "Hoy · incluye vencidas" => pending.select { |task| task.due_on && task.due_on <= today },
      "Esta semana" => pending.select { |task| task.due_on && task.due_on > today && task.due_on <= today.end_of_week },
      "Más tarde" => pending.select { |task| task.due_on.nil? || task.due_on > today.end_of_week }
    }
    @completed_tasks = tasks.select { |task| task.status == "done" }
  end
end
