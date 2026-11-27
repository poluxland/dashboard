require "test_helper"
require "minitest/mock"

class AprWeeklyDeliveryTest < ActiveSupport::TestCase
  RECIPIENTS = "fernando.gonzalez@msindustrial.cl, jose.jerez@msindustrial.cl"

  setup do
    @monday = Time.find_zone!(AprDay::ZONE).local(2026, 11, 30, 8)
    @apr = DashboardUser.create!(email: "semanal-apr@msindustrial.cl")
  end

  test "delivers once on Monday and includes the previous week across plants with or without a daily closing" do
    travel_to @monday do
      activity_on(7, "PTM", "Inspección de apertura", duration_minutes: 35)
      last = activity_on(1, "VTS", "Permiso de trabajo final", duration_minutes: 40, outcome: "follow_up",
        severity: "grave", responsible: "Supervisor", due_on: Date.new(2026, 12, 1))
      last.apr_day.close!(@apr.email)
      activity_on(8, "LCA", "Fuera del período anterior")
      activity_on(0, "CALBUCO", "Fuera del período siguiente")

      assert_no_difference "ActionMailer::Base.deliveries.size" do
        dispatch(@monday - 1.day)
        dispatch(@monday - 1.minute)
        dispatch(@monday + 1.day)
        AprWeeklyDelivery.dispatch_due(reference_time: @monday, recipients: "")
      end

      assert_difference "ActionMailer::Base.deliveries.size", 1 do
        dispatch(@monday)
        dispatch(@monday + 1.minute)
      end
      report = AprWeeklyDelivery.find_by!(week_start: Date.new(2026, 11, 23))
      assert report.sent_at?
      message = ActionMailer::Base.deliveries.last
      assert_equal RECIPIENTS.split(", "), report.recipients
      assert_equal report.recipients, message.to
      assert_includes message.subject, "23-11-2026 al 29-11-2026"
      [ message.text_part, message.html_part ].each do |part|
        content = part.body.decoded
        assert_includes content, "Inspección de apertura"
        assert_includes content, "Permiso de trabajo final"
        assert_includes content, "1 h 15 min"
        assert_includes content, "Supervisor"
        assert_includes content, "Grave"
        assert_not_includes content, "Comentario interno APR"
        assert_not_includes content, "Fuera del período"
      end
    end
  end

  test "a failed send can be retried and an empty week is reported" do
    failing_mail = Object.new
    def failing_mail.deliver_now
      raise IOError, "SMTP unavailable"
    end

    AprDayMailer.stub(:weekly_summary, failing_mail) do
      assert_raises(IOError) { dispatch(@monday) }
    end
    report = AprWeeklyDelivery.find_by!(week_start: Date.new(2026, 11, 23))
    assert_nil report.sent_at

    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      dispatch(@monday + 1.minute)
    end
    assert report.reload.sent_at?
    assert_includes ActionMailer::Base.deliveries.last.text_part.body.decoded, "Sin actividades registradas en el período."
  end

  test "the weekly message combines the daily register and overlapping history with summaries of archived activities" do
    history = AprHistoryEntry.create!(
      date: Date.new(2026, 11, 22), end_date: Date.new(2026, 11, 24), plant: "PTM",
      source_file: "Histórico de prueba.xlsx", source_sheet: "Informe", source_date: "22 a 24",
      source_row: 3, source_end_row: 3, source_fingerprint: "weekly-history",
      activities: [ "Actividad con una nota reservada" ], observations: "Comentario reservado del histórico",
      activity_details: { "1" => { "type" => "Capacitación", "place" => "Sala de capacitación" } }
    )
    outside = history.dup
    outside.update!(date: Date.new(2026, 11, 20), end_date: Date.new(2026, 11, 22), source_row: 4, source_end_row: 4,
      activity_details: { "1" => { "type" => "Actividad fuera de semana" } })
    rest = history.dup
    rest.update!(date: Date.new(2026, 11, 25), end_date: Date.new(2026, 11, 25), source_row: 5, source_end_row: 5,
      day_status: "Descanso compensatorio")

    travel_to @monday do
      activity_on(1, "VTS", "Actividad del registro diario", duration_minutes: 20)
      dispatch(@monday)
    end

    message = ActionMailer::Base.deliveries.last
    [ message.text_part, message.html_part ].each do |part|
      content = part.body.decoded
      assert_includes content, "2 actividades"
      assert_includes content, "Tiempo informado 20 min"
      assert_includes content, "Actividad del registro diario"
      assert_includes content, "Capacitación · Sala de capacitación"
      assert_includes content, "/registro-actividades/historico/#{history.id}"
      assert_not_includes content, "Sin actividades registradas"
      assert_not_includes content, "Actividad fuera de semana"
      assert_not_includes content, "Actividad con una nota reservada"
      assert_not_includes content, "Comentario reservado del histórico"
    end
  end

  private

  def dispatch(time)
    AprWeeklyDelivery.dispatch_due(reference_time: time, recipients: RECIPIENTS)
  end

  def activity_on(days_ago, plant, title, **overrides)
    day = AprDay.create!(date: @monday.to_date - days_ago.days, plant: plant, apr: @apr)
    day.activities.create!(
      { title: title, sector: "Granel", activity_type: "Inspección", duration_minutes: 20,
        outcome: "none", observations: "Comentario interno APR" }.merge(overrides)
    )
  end
end
