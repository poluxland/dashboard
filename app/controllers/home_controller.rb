class HomeController < ApplicationController
  def index
    today = Time.current.in_time_zone("America/Santiago").to_date
    @trabajos_report = TrabajosReport.new(today: today) if task_admin?
    tasks = Task.includes(:items).where(assignee_email: current_user[:email].to_s.downcase).ordered.to_a
    pending = tasks.reject { |task| task.status == "done" }
    @group_by = %w[category plant status date].include?(params[:group_by]) ? params[:group_by] : "category"
    @task_groups = case @group_by
    when "category" then Task::CATEGORIES.to_h { |value, label| [ label, pending.select { |task| task.category == value } ] }
    when "plant" then Task::PLANTS.to_h { |value| [ value, pending.select { |task| task.plant == value } ] }
    when "status" then Task::STATUSES.to_h { |value, label| [ label, tasks.select { |task| task.status == value } ] }
    else
      {
        "Hoy · incluye vencidas" => pending.select { |task| task.due_on && task.due_on <= today },
        "Esta semana" => pending.select { |task| task.due_on && task.due_on > today && task.due_on <= today.end_of_week },
        "Más tarde" => pending.select { |task| task.due_on.nil? || task.due_on > today.end_of_week }
      }
    end
    @completed_tasks = tasks.select { |task| task.status == "done" }
  end
end
