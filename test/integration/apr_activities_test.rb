require "test_helper"
require "minitest/mock"

class AprActivitiesTest < ActionDispatch::IntegrationTest
  APR_EMAIL = "apr-ptm@msindustrial.cl"

  setup do
    @date = AprDay.today.yesterday
    sign_in_with_google(email: APR_EMAIL)
  end

  test "registers an activity at a time and remembers the chosen plant" do
    get new_apr_activity_path(plant: "VTS", date: @date)
    assert_response :success
    assert_select "select[name='apr_activity[plant]'] option[selected][value='VTS']"
    assert_select "form[data-controller='apr-finding'] select", count: 5

    assert_difference [ "AprActivity.count", "AprDay.count" ], 1 do
      post apr_activities_path, params: { commit_action: "add_another",
        apr_activity: activity_fields(plant: "VTS", created_by_email: "other@msindustrial.cl") }
    end
    assert_redirected_to new_apr_activity_path(plant: "VTS", date: @date)
    record = AprActivity.last
    assert_equal [ "VTS", @date, APR_EMAIL ], [ record.apr_day.plant, record.apr_day.date, record.created_by_email ]
    assert_equal 75, record.duration_minutes
    get apr_activities_path(date: @date)
    assert_select "h1", "Registro de actividades"
    assert_select "td", text: "1 h 15 min"
    assert_select "#aprDropdown + ul a[href=?]", apr_activities_path, text: "Registro de actividades"
    get apr_activities_path(date: @date, activity_type: "Inspección")
    assert_select "p", text: "Selección · 1 actividad · 1 h 15 min"

    patch apr_activity_path(record), params: { apr_activity: activity_fields(plant: "LCA", date: @date.yesterday.iso8601) }
    assert_redirected_to apr_activity_path(record)
    assert_equal [ "LCA", @date.yesterday ], [ record.reload.apr_day.plant, record.apr_day.date ]
    assert_equal APR_EMAIL, record.updated_by_email
  end

  test "finding and duration validation match the selected outcome" do
    assert_no_difference [ "AprActivity.count", "AprDay.count" ] do
      create_activity(outcome: "follow_up", severity: "grave")
      assert_response :unprocessable_entity
      assert_select "[role=alert]", text: /Responsable/
      create_activity(outcome: "corrected")
      assert_response :unprocessable_entity
      create_activity(duration_hours: "24", duration_remainder: "1")
      assert_response :unprocessable_entity
      create_activity(date: AprDay.today.tomorrow.iso8601)
      assert_response :unprocessable_entity
    end
    create_activity(outcome: "corrected", severity: "grave")
    assert_equal [ "corrected", "grave", nil ], AprActivity.last.values_at(:outcome, :severity, :follow_up_status)
  end

  test "closing sends the APR a snapshot by plant and pending items stay editable" do
    create_activity(**finding_fields)
    pending = AprActivity.last
    day = pending.apr_day
    create_activity(title: "Actividad Calera", plant: "LCA")
    calera_day = AprActivity.last.apr_day
    assert_not_equal day, calera_day

    get apr_day_path(day)
    assert_response :success
    assert_select "button", "Cerrar día y enviar correo"
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      post close_apr_day_path(day), params: { closed_by_email: "forged@example.com", recipients: [ "out@example.com" ] }
    end
    assert_redirected_to apr_day_path(day)
    assert_equal APR_EMAIL, day.reload.closed_by_email
    assert day.sent_at?
    assert_nil calera_day.reload.closed_at
    message = ActionMailer::Base.deliveries.last
    assert_equal [ APR_EMAIL ], message.to
    assert_equal [ APR_EMAIL ], message.reply_to
    assert_includes message.text_part.decoded, "Hallazgos graves: 1"
    assert_includes message.html_part.decoded, apr_day_path(day)
    assert_not_includes message.text_part.decoded, pending.observations
    assert_not_includes message.html_part.decoded, pending.title
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      post close_apr_day_path(day)
      post send_email_apr_day_path(day)
    end

    assert_no_difference "AprActivity.count" do
      create_activity(title: "Agregada después del cierre")
      assert_response :unprocessable_entity
    end
    patch apr_activity_path(pending), params: { apr_activity: activity_fields(plant: "VTS", title: "Cambio posterior") }
    assert_response :unprocessable_entity
    assert_equal day.id, pending.reload.apr_day_id

    patch follow_up_apr_activity_path(pending), params: { status: "in_progress" }
    assert_equal "in_progress", pending.reload.follow_up_status
    patch follow_up_apr_activity_path(pending), params: { status: "closed", resolution: " " }
    assert_response :unprocessable_entity
    assert_select "textarea[name=resolution]"
    assert_equal "in_progress", pending.reload.follow_up_status
    patch follow_up_apr_activity_path(pending), params: { status: "closed", resolution: "Se instaló la protección." }
    assert_redirected_to apr_activity_path(pending)
    assert_equal [ "closed", "Se instaló la protección.", APR_EMAIL ],
      pending.reload.values_at(:follow_up_status, :resolution, :resolved_by_email)
    assert pending.resolved_at?
    assert_equal 1, day.reload.email_summary.fetch("pending").size
    get follow_ups_apr_activities_path(plant: "PTM", status: "closed")
    assert_select "td", text: "Cerrado"
    get follow_ups_apr_activities_path(plant: "PTM")
    assert_select "td", text: "Cerrado", count: 0
  end

  test "the preview and activity stay private and failed delivery can be retried" do
    create_activity
    record = AprActivity.last
    day = record.apr_day
    sign_in_with_google(email: "otro-apr@msindustrial.cl")
    get apr_activity_path(record)
    assert_response :not_found
    post close_apr_day_path(day)
    assert_response :not_found
    delete logout_path
    get apr_activities_path
    assert_redirected_to login_path

    sign_in_with_google(email: APR_EMAIL)
    failing_mail = Object.new
    def failing_mail.deliver_now
      raise IOError, "No SMTP"
    end
    AprDayMailer.stub(:summary, failing_mail) { post close_apr_day_path(day) }
    assert day.reload.closed_at?
    assert_nil day.sent_at
    assert_match "reintenta", flash[:alert]
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      post send_email_apr_day_path(day)
    end
    assert day.reload.sent_at?
  end

  test "configured recipients can open the closed report for their plant without gaining editing rights" do
    recipient = "revision-vts@msindustrial.cl"
    env_key = "APR_ACTIVITY_REPORT_RECIPIENTS_VTS"
    original = ENV[env_key]
    ENV[env_key] = recipient

    create_activity(plant: "VTS")
    activity = AprActivity.last
    day = activity.apr_day
    sign_in_with_google(email: recipient)
    get apr_day_path(day)
    assert_response :not_found
    sign_in_with_google(email: APR_EMAIL)
    post close_apr_day_path(day)
    assert_equal [ APR_EMAIL, recipient ], day.reload.recipients

    sign_in_with_google(email: recipient)
    get apr_day_path(day)
    assert_response :success
    assert_select "button", text: "Cerrar día y enviar correo", count: 0
    get apr_activity_path(activity)
    assert_response :success
    patch apr_activity_path(activity), params: { apr_activity: activity_fields }
    assert_response :not_found
  ensure
    ENV[env_key] = original
  end

  private

  def activity_fields(**overrides)
    {
      date: @date.iso8601, plant: "PTM", sector: "Granel", activity_type: "Inspección",
      title: "Inspección en zona de descarga", observations: "Comentario reservado de la actividad.",
      duration_hours: "1", duration_remainder: "15", outcome: "none"
    }.merge(overrides)
  end

  def finding_fields
    { outcome: "follow_up", severity: "grave", responsible: "Supervisor", due_on: AprDay.today.tomorrow.iso8601 }
  end

  def create_activity(**overrides)
    post apr_activities_path, params: { apr_activity: activity_fields(**overrides) }
  end
end
