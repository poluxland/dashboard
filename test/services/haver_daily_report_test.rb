require "test_helper"

class HaverDailyReportTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "uses the preceding three slots, marks a late night shift, and reuses cumulative Haver KPIs" do
    day = Date.new(2026, 11, 18)
    cutoff = HaverDailyReport.cutoff_for(day.next_day)
    add_report(day - 1, "TM", at: cutoff - 1.day, sacks: 2000)
    add_report(day, "TM", at: cutoff - 15.hours, sacks: 8000, hours: 4)
    add_report(day, "TT", at: cutoff - 7.hours, sacks: 4000, hours: 2)
    add_report(day, "TT", at: cutoff + 30.minutes, sacks: 9000, hours: 4)
    add_report(day, "TN", at: cutoff + 1.hour, sacks: 0, hours: 0)

    report = HaverDailyReport.new(scheduled_at: cutoff)
    assert_equal %w[TM TT TN], report.shifts.pluck(:shift)
    assert_equal [ true, true, false ], report.shifts.pluck(:received)
    assert_equal 8000, report.shifts.first[:good_bags]
    assert_equal 4000, report.shifts.second[:good_bags]
    assert_equal "En curso al corte · cierra 06:00", report.shifts.last[:status]
    assert_nil report.shifts.last[:good_bags]
    assert_equal [ 300, 350, 350 ], report.periods.map { |period| period[:totals][:tons] }
    assert_in_delta 50, report.periods.first[:totals][:rate]
  end

  test "Monday uses the latest scheduled turns across the weekend" do
    calendar = Date.new(2026, 11, 16)
    report = HaverDailyReport.new(scheduled_at: HaverDailyReport.cutoff_for(calendar))
    assert_equal [
      [ Date.new(2026, 11, 13), "TT" ],
      [ Date.new(2026, 11, 13), "TN" ],
      [ Date.new(2026, 11, 14), "TM" ]
    ], report.shifts.map { |row| row.values_at(:date, :shift) }
    assert_equal Date.new(2026, 11, 9)..Date.new(2026, 11, 14), report.periods.second[:range]
  end

  test "test mail uses only its two recipients and includes HTML and text KPIs" do
    cutoff = HaverDailyReport.cutoff_for(Date.new(2026, 11, 19))
    message = HaverDailyMailer.report(scheduled_at: cutoff, test: true).message
    assert_equal %w[jose.jerez@msindustrial.cl fernando.gonzalez@msindustrial.cl].sort, message.destinations.sort
    assert_match(/\APRUEBA/, message.subject)
    assert_includes message.html_part.decoded, "KPI acumulados"
    assert_includes message.text_part.decoded, "TRES TURNOS ANTERIORES"
    assert_includes message.text_part.decoded, "05:00"

    daily = HaverDailyMailer.report(scheduled_at: cutoff).message
    assert_equal [ "camila.ramirez@meloncementos.cl" ], daily.to
    assert_equal 13, daily.cc.size
    assert_includes daily.cc, "guillermo.roco@meloncementos.cl"
    assert_includes daily.cc, "jefesturno.planta@meloncementos.cl"
  end

  test "worker uses Chilean 05:00 in both seasons and sends a weekday slot once" do
    winter = HaverDailyReport.cutoff_for(Date.new(2026, 7, 13))
    summer = HaverDailyReport.cutoff_for(Date.new(2026, 11, 16))
    assert_equal 9, winter.utc.hour
    assert_equal 8, summer.utc.hour
    assert_no_emails do
      HaverDailyDelivery.dispatch_due(reference_time: summer - 1.minute)
      HaverDailyDelivery.dispatch_due(reference_time: summer + 2.hours)
      HaverDailyDelivery.dispatch_due(reference_time: HaverDailyReport.cutoff_for(Date.new(2026, 11, 14)))
    end
    assert_emails 1 do
      HaverDailyDelivery.dispatch_due(reference_time: summer)
      HaverDailyDelivery.dispatch_due(reference_time: summer + 1.minute)
    end
    assert HaverDailyDelivery.find_by!(scheduled_on: summer.in_time_zone(HaverDailyReport::CHILE).to_date).sent_at?
  end

  private

  def add_report(date, turno, at:, sacks:, hours: 1)
    fields = EnvasadoraReport::SILOS.values.flat_map { |silo| silo[:readings] }.index_with(10)
    EnvasadoraReport.create!(fields.merge(date: date, turno: turno, created_at: at, author_email: "test@msindustrial.cl",
                                         prodhaver: sacks, horas_haver: hours, sacos_rotos_haver: 0,
                                         sacos_descartados_haver: 0, sacos_no_reconocidos_haver: 0))
  end
end
