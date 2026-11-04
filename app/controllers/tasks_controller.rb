class TasksController < ApplicationController
  before_action :require_task_admin!, except: :update

  def index
    @tasks = Task.ordered
    @tasks = @tasks.where(assignee_email: params[:assignee].to_s.strip.downcase) if params[:assignee].present?
    @assignees = Task.distinct.order(:assignee_email).pluck(:assignee_email)
  end

  def new
    @task = Task.new
  end

  def create
    @task = Task.new(task_params.merge(creator_email: current_user[:email]))
    if @task.save
      redirect_to tasks_path, notice: "Tarea creada."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @task = Task.find(params[:id])
  end

  def update
    scope = task_admin? ? Task.all : Task.where(assignee_email: current_user[:email].to_s.downcase)
    @task = scope.find(params[:id])
    attributes = task_admin? ? task_params : params.require(:task).permit(:status)
    if @task.update(attributes)
      redirect_to(task_admin? ? tasks_path : root_path, notice: "Tarea actualizada.")
    elsif task_admin?
      render :edit, status: :unprocessable_entity
    else
      redirect_to root_path, alert: @task.errors.full_messages.to_sentence
    end
  end

  private

  def require_task_admin!
    head :forbidden unless task_admin?
  end

  def task_params
    params.require(:task).permit(:title, :description, :assignee_email, :due_on, :priority, :status)
  end
end
