class TaskCommentsController < ApplicationController
  def create
    scope = task_admin? ? Task.all : Task.where(assignee_email: current_user[:email].to_s.downcase)
    @task = scope.find(params[:task_id])
    @comment = @task.comments.build(params.require(:task_comment).permit(:body))
    @comment.author_email = current_user[:email].to_s.downcase
    @comment.author_name = current_user[:name]
    if @comment.save
      redirect_to task_path(@task, anchor: "comment-#{@comment.id}"), notice: "Comentario publicado.", status: :see_other
    else
      render "tasks/show", status: :unprocessable_entity
    end
  end
end
