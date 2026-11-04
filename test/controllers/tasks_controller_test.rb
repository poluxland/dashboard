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
    assert_response :success
    assert_select "input[name=?]", "task[title]", count: 0
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

  test "board supports dragging and saves status via JSON" do
    sign_in_with_google(email: "jose.jerez@msindustrial.cl")
    get tasks_path
    assert_select "section[data-task-status]", count: 3
    assert_select "article[draggable=true]", count: 1
    patch task_path(@task), params: { task: { status: "in_progress" } }, as: :json
    assert_response :success
    assert_equal "in_progress", @task.reload.status
    patch task_path(@task), params: { task: { status: "invalid" } }, as: :json
    assert_response :unprocessable_entity
    assert_equal "in_progress", @task.reload.status
  end

  test "checklist updates are scoped and progress is computed" do
    item = @task.items.create!(title: "Paso", due_on: Date.current)
    other = Task.create!(title: "Otra", assignee_email: "otro@msindustrial.cl", creator_email: @task.creator_email)
    foreign_item = other.items.create!(title: "Privado", due_on: Date.current)
    sign_in_with_google
    patch task_path(@task), params: { task: { items_attributes: [ { id: item.id, completed: true, title: "Alterado" } ] } }, as: :json
    assert_response :success
    assert_equal 100, response.parsed_body["completion_percentage"]
    assert_equal "Paso", item.reload.title
    assert item.completed?
    patch task_path(@task), params: { task: { items_attributes: [ { id: foreign_item.id, completed: true } ] } }, as: :json
    assert_response :not_found
    assert_not foreign_item.reload.completed?
    get task_path(other)
    assert_response :not_found
    get task_path(@task)
    assert_response :success
    assert_select "input[type=checkbox][checked]", count: 1
  end

  test "board groups by plant and category without enabling status dragging" do
    sign_in_with_google(email: "jose.jerez@msindustrial.cl")
    %w[plant category].each do |group|
      get tasks_path, params: { group_by: group }
      assert_response :success
      assert_select "section", count: 4
      assert_select "article[draggable]", count: 0
    end
  end

  test "dynamically added checklist rows persist through create and edit" do
    sign_in_with_google(email: "jose.jerez@msindustrial.cl")
    get new_task_path
    template = Nokogiri::HTML(response.body).at_css('template[data-task-items-target="template"]')
    rows = {}
    [ "123e4567-e89b-12d3-a456-426614174000", "123e4567-e89b-12d3-a456-426614174001" ].each_with_index do |index, number|
      template.css("input[name]").each do |input|
        name = input["name"].gsub("NEW_ITEM", index)
        rows[name] = case name
        when /\[title\]$/ then "Paso #{number + 1}"
        when /\[due_on\]$/ then "2026-11-10"
        else input["value"]
        end
      end
    end
    params = Rack::Utils.parse_nested_query(URI.encode_www_form(rows))
    params["task"].merge!("title" => "Con checklist", "assignee_email" => "usuario@msindustrial.cl")
    assert_difference("TaskItem.count", 2) { post tasks_path, params: params }
    assert_redirected_to tasks_path
    task = Task.order(:id).last
    assert_equal [ "Paso 1", "Paso 2" ], task.items.order(:id).pluck(:title)
    patch task_path(task), params: { task: { items_attributes: { "1730000000002" => { title: "Paso 3", due_on: "2026-11-11" } } } }
    assert_redirected_to tasks_path
    assert_equal 3, task.items.reload.size
  end

  test "invalid tasks render errors" do
    sign_in_with_google(email: "jose.jerez@msindustrial.cl")
    assert_no_difference("Task.count") do
      post tasks_path, params: { task: { title: "", assignee_email: "external@example.com", status: "unknown" } }
    end
    assert_response :unprocessable_entity
  end
end
