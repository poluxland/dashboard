class TasksController < ApplicationController
  before_action :require_task_admin!, except: [ :show, :update ]

  def index
    @group_by = %w[status plant category].include?(params[:group_by]) ? params[:group_by] : "status"
    @groups = { "status" => Task::STATUSES, "plant" => Task::PLANTS.index_with(&:itself), "category" => Task::CATEGORIES }.fetch(@group_by)
    @tasks = Task.includes(:items).ordered
    @tasks = @tasks.where(assignee_email: params[:assignee].to_s.strip.downcase) if params[:assignee].present?
    @assignees = Task.distinct.order(:assignee_email).pluck(:assignee_email)
  end

  def show
    @task = accessible_tasks.includes(:items).find(params[:id])
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
    scope = accessible_tasks
    @task = scope.find(params[:id])
    attributes = task_admin? ? task_params : params.require(:task).permit(:status, items_attributes: [ :id, :completed ])
    if @task.update(attributes)
      respond_to do |format|
        format.html { redirect_to(task_admin? ? tasks_path : root_path, notice: "Tarea actualizada.") }
        format.json { render json: { status: @task.status, completion_percentage: @task.completion_percentage } }
      end
    elsif request.format.json?
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    elsif task_admin?
      render :edit, status: :unprocessable_entity
    else
      redirect_to root_path, alert: @task.errors.full_messages.to_sentence
    end
  end

  private

  def accessible_tasks
    task_admin? ? Task.all : Task.where(assignee_email: current_user[:email].to_s.downcase)
  end

  def require_task_admin!
    head :forbidden unless task_admin?
  end

  def task_params
    params.require(:task).permit(:title, :description, :assignee_email, :due_on, :priority, :status, :category, :plant, items_attributes: [ :id, :title, :due_on, :completed, :_destroy ])
  end
end
