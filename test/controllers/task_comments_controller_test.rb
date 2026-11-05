require "test_helper"

class TaskCommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @task = Task.create!(title: "Revisar equipo", assignee_email: "usuario@msindustrial.cl", creator_email: "fernando.gonzalez@msindustrial.cl")
  end

  test "assignee can comment with server assigned author and escaped content" do
    sign_in_with_google
    assert_difference("TaskComment.count") do
      post task_comments_path(@task), params: { task_comment: { body: "<script>alert(1)</script>", author_email: "falso@msindustrial.cl", created_at: "2000-01-01" } }
    end
    comment = @task.comments.sole
    assert_equal "usuario@msindustrial.cl", comment.author_email
    assert_equal "Usuario Industrial", comment.author_name
    assert_redirected_to task_path(@task, anchor: "comment-#{comment.id}")
    follow_redirect!
    assert_response :success
    assert_select "section script", count: 0
    assert_includes response.body, "&lt;script&gt;alert(1)&lt;/script&gt;"
    assert_select "ol li:first-child", text: /fernando.gonzalez@msindustrial.cl.*creó la tarea/m
    assert_select "time", count: 2
    assert_select "#comment-#{comment.id}", text: /usuario@msindustrial.cl/
  end

  test "admin can comment and old tasks show their original creation date" do
    @task.update_columns(created_at: Time.utc(2026, 10, 10, 15, 30))
    sign_in_with_google(email: "jose.jerez@msindustrial.cl")
    get task_path(@task)
    assert_select "ol li:first-child time", text: "10/10/2026, 12:30 · Chile"
    post task_comments_path(@task), params: { task_comment: { body: "Revisado" } }
    assert_response :see_other
  end

  test "anonymous and unrelated users cannot post or read comments" do
    post task_comments_path(@task), params: { task_comment: { body: "No autorizado" } }
    assert_redirected_to login_path
    sign_in_with_google(email: "otro@msindustrial.cl")
    assert_no_difference("TaskComment.count") do
      post task_comments_path(@task), params: { task_comment: { body: "No autorizado" } }
    end
    assert_response :not_found
    get task_path(@task)
    assert_response :not_found
  end

  test "blank and oversized comments render validation and preserve text" do
    sign_in_with_google
    [ "   ", "a" * 5001 ].each do |body|
      assert_no_difference("TaskComment.count") do
        post task_comments_path(@task), params: { task_comment: { body: body } }
      end
      assert_response :unprocessable_entity
      assert_select ".alert-danger"
    end
    assert_select "textarea", text: "a" * 5001
  end
end
