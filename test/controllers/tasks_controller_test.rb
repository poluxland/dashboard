require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @task = Task.create!(title: "Inspeccionar equipo", assignee_email: "usuario@msindustrial.cl", creator_email: "jose.jerez@msindustrial.cl", due_on: Time.current.in_time_zone("America/Santiago").to_date)
  end

  test "anonymous users must authenticate" do
    get tasks_path
    assert_redirected_to login_path
  end

  test "both admins can create and edit tasks" do
    %w[jose.jerez@msindustrial.cl fernando.gonzalez@msindustrial.cl].each do |email|
      sign_in_with_google(email: email)
      get tasks_path
      assert_response :success
      get new_task_path
      assert_response :success
      assert_select "select[name=?] option[value=?]", "task[assignee_email]", email
      assert_select "input[type=email]", count: 0
      assert_difference("Task.count") do
        post tasks_path, params: { task: { title: "Revisar", assignee_email: " Otro@msindustrial.cl ", creator_email: "fake", priority: "high" } }
      end
      assert_equal email, Task.last.creator_email
      assert_equal "otro@msindustrial.cl", Task.last.assignee_email
      get edit_task_path(@task)
      assert_response :success
    end
  end

  test "regular users cannot administer or change other users tasks" do
    sign_in_with_google
    get tasks_path
    assert_response :forbidden
    get new_task_path
    assert_response :forbidden
    get edit_task_path(@task)
    assert_response :forbidden
    assert_no_difference("Task.count") { post tasks_path, params: { task: { title: "Forbidden" } } }
    assert_response :forbidden
    other = Task.create!(title: "Privada", assignee_email: "otro@msindustrial.cl", creator_email: "jose.jerez@msindustrial.cl")
    patch task_path(other), params: { task: { status: "done" } }
    assert_response :not_found
    assert_equal "pending", other.reload.status
    patch task_path(@task), params: { task: { status: "done", title: "Changed", assignee_email: "otro@msindustrial.cl" } }
    assert_redirected_to root_path
    assert_equal "done", @task.reload.status
    assert_equal "Inspeccionar equipo", @task.title
    assert_equal "usuario@msindustrial.cl", @task.assignee_email
  end

  test "home groups only own tasks by Chilean dates" do
    travel_to Time.utc(2026, 11, 4, 15) do
      @task.update!(due_on: Date.new(2026, 11, 3))
      [ [ "Semana", Date.new(2026, 11, 8) ], [ "Futura", Date.new(2026, 11, 9) ], [ "Sin fecha", nil ] ].each do |title, date|
        Task.create!(title: title, due_on: date, assignee_email: @task.assignee_email, creator_email: @task.creator_email)
      end
      Task.create!(title: "Invisible", assignee_email: "otro@msindustrial.cl", creator_email: @task.creator_email)
      sign_in_with_google
      get root_path
      assert_response :success
      assert_select "section", count: 3
      assert_select "section:nth-child(1)", text: /Inspeccionar equipo/
      assert_select "section:nth-child(2)", text: /Semana/
      assert_select "section:nth-child(3)", text: /Futura.*Sin fecha/m
      assert_select "article", count: 4
      assert_select "a[href=?]", tasks_path, count: 0
    end
  end

  test "invalid tasks render errors" do
    sign_in_with_google(email: "jose.jerez@msindustrial.cl")
    assert_no_difference("Task.count") do
      post tasks_path, params: { task: { title: "", assignee_email: "external@example.com", status: "unknown" } }
    end
    assert_response :unprocessable_entity
  end
end
