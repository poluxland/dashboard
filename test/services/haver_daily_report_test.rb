require "test_helper"

class HaverDailyReportTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "uses the preceding three slots, marks a late night shift, and reuses cumulative Haver KPIs" do
    day = Date.new(2026, 11, 18)
    cutoff = HaverDailyReport.cutoff_for(day.next_day)
    add_report(day - 1, "TM", at: cutoff - 1.day, sacks: 2000)
    add_report(day - 2, "TM", at: cutoff - 2.days, sacks: 0, hours: 0)
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
    assert_equal [ 300, 350, 350, 300 ], report.periods.map { |period| period[:totals][:tons] }
    assert_in_delta 50, report.periods.first[:totals][:rate]
    assert_equal "2 de 3 turnos al corte", report.full_day[:coverage]
    assert_equal day..day, report.full_day[:range]
    assert_in_delta 50, report.full_day[:totals][:rate]
    assert_equal (day - 6)..day, report.production_range
    assert_equal [ day - 1, day ], report.production_by_day.pluck(:date)
    assert_equal({ date: day, tons: 300.0, rate: 50.0 }, report.production_by_day.last)
  end

  test "Monday uses the latest scheduled turns across the weekend" do
    calendar = Date.new(2026, 11, 16)
    cutoff = HaverDailyReport.cutoff_for(calendar)
    friday = Date.new(2026, 11, 13)
    saturday = friday.next_day
    add_report(friday, "TT", at: cutoff - 2.days, sacks: 4000)
    add_report(friday, "TN", at: cutoff - 2.days, sacks: 2000)
    add_report(saturday, "TM", at: cutoff - 1.day, sacks: 8000, hours: 4)
    report = HaverDailyReport.new(scheduled_at: cutoff)
    assert_equal [
      [ Date.new(2026, 11, 13), "TT" ],
      [ Date.new(2026, 11, 13), "TN" ],
      [ Date.new(2026, 11, 14), "TM" ]
    ], report.shifts.map { |row| row.values_at(:date, :shift) }
    assert_equal Date.new(2026, 11, 9)..Date.new(2026, 11, 14), report.periods.second[:range]
    assert_equal saturday..saturday, report.full_day[:range]
    assert_equal "1 de 1 turno al corte", report.full_day[:coverage]
    assert_equal 350, report.periods.first[:totals][:tons]
    assert_equal 200, report.full_day[:totals][:tons]
  end

  test "the full day shows zero production for an explicitly idle shift" do
    day = Date.new(2026, 11, 18)
    cutoff = HaverDailyReport.cutoff_for(day.next_day)
    add_report(day, "TM", at: cutoff - 15.hours, sacks: 0, hours: 0)
    report = HaverDailyReport.new(scheduled_at: cutoff)
    assert_equal "1 de 3 turnos al corte", report.full_day[:coverage]
    assert_equal 0, report.full_day[:totals][:good_bags]
    assert_equal 0.0, report.full_day[:totals][:tons]
    assert_nil report.full_day[:totals][:rate]
  end

  test "test mail uses only its three recipients and includes HTML and text KPIs" do
    cutoff = HaverDailyReport.cutoff_for(Date.new(2026, 11, 19))
    message = HaverDailyMailer.report(scheduled_at: cutoff, test: true).message
    assert_equal %w[claudio.villanueva@msindustrial.cl fernando.gonzalez@msindustrial.cl jose.jerez@msindustrial.cl], message.destinations.sort
    assert_match(/\APRUEBA/, message.subject)
    assert_includes message.html_part.decoded, "KPI acumulados"
    assert_includes message.text_part.decoded, "TRES TURNOS ANTERIORES"
    assert_includes message.text_part.decoded, "05:00"
    assert_includes message.html_part.decoded, "Sin producción Haver informada en este período."
    assert_not_includes message.html_part.decoded, "Turnos con estimación Vorne"
    assert_not_includes message.text_part.decoded, "Turnos con estimación Vorne"
    html = Nokogiri::HTML(message.html_part.decoded)
    %w[haver-email-turnos haver-email-acumulados].each do |table|
      headers = html.css("##{table} thead th")
      assert_equal 5, headers.size
      assert_includes headers.last.text, "Día completo"
    end
    assert_includes message.text_part.decoded, "Día completo 18/11 · 0 de 3 turnos al corte"
    button = html.css("a").find { |link| link.text == "Ver Informe Haver" }
    assert_equal "/informes/haver", URI.parse(button["href"]).path

    daily = HaverDailyMailer.report(scheduled_at: cutoff).message
    assert_equal [ "camila.ramirez@meloncementos.cl" ], daily.to
    assert_equal 14, daily.cc.size
    assert_includes daily.cc, "claudio.villanueva@msindustrial.cl"
    assert_includes daily.cc, "guillermo.roco@meloncementos.cl"
    assert_includes daily.cc, "jefesturno.planta@meloncementos.cl"
  end

  test "email embeds the daily PNG and includes its data in plain text across a month boundary" do
    day = Date.new(2026, 11, 3)
    cutoff = HaverDailyReport.cutoff_for(day.next_day)
    add_report(Date.new(2026, 10, 29), "TM", at: cutoff - 6.days + 12.hours, sacks: 8000, hours: 4)
    add_report(day, "TM", at: cutoff - 15.hours, sacks: 4000, hours: 2)

    message = HaverDailyMailer.report(scheduled_at: cutoff, test: true).message
    image = message.attachments["haver-produccion-rendimiento.png"]
    assert_equal "image/png", image.mime_type
    assert image.inline?
    assert image.body.decoded.start_with?(HaverEmailChart::PNG_SIGNATURE)
    assert_operator image.body.decoded.bytesize, :>, 1000
    assert_includes message.html_part.decoded, image.url
    assert_includes message.text_part.decoded, "29/10 · Producción 200 t · Rendimiento 50 t/h"
    assert_not_includes message.text_part.decoded, "30/10 · Producción"
    assert_includes message.text_part.decoded, "Del 28/10 al 03/11"
  end

  test "Pareto includes 30 days of reported detentions and omits Missing Reason" do
    day = Date.new(2026, 11, 18)
    start = day - 29
    cutoff = HaverDailyReport.cutoff_for(day.next_day)
    [ start - 1, start, day ].each { |date| add_report(date, "TM", at: cutoff - 1.day, sacks: 4000) }
    source = TptImport.create!(filename: "vorne.xlsx", author_email: "test@msindustrial.cl")
    add_event(source, start - 1, "Fuera del período", 60, at: cutoff - 1.hour)
    add_event(source, start, "Falla en cinta", 30, at: cutoff - 1.hour)
    add_event(source, day, "Revisión", 15, at: cutoff - 1.hour)
    add_event(source, day, "  mIsSiNg ReAsOn  ", 150, at: cutoff - 1.hour)
    add_event(source, day, "Cargado después", 90, at: cutoff + 1.hour)

    report = HaverDailyReport.new(scheduled_at: cutoff)
    assert_equal start..day, report.pareto_range
    assert_equal day, report.pareto_last_date
    assert_equal [ "Falla en cinta", "Revisión" ], report.pareto_causes.pluck(:label)
    assert_equal [ 30, 15 ], report.pareto_causes.pluck(:minutes)
    assert_in_delta 66.6667, report.pareto_causes.first[:cumulative]
    assert_equal 100, report.pareto_causes.last[:cumulative]

    message = HaverDailyMailer.report(scheduled_at: cutoff, test: true).message
    image = message.attachments["haver-pareto-detenciones.png"]
    assert_equal "image/png", image.mime_type
    assert image.inline?
    assert image.body.decoded.start_with?(HaverEmailChart::PNG_SIGNATURE)
    assert_includes message.html_part.decoded, image.url
    assert_includes message.text_part.decoded, "Falla en cinta · 30 min"
    assert_no_match(/missing reason/i, message.text_part.decoded)
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

  def add_event(source, date, reason, minutes, at:)
    source.tpt_events.create!(started_at: Time.utc(date.year, date.month, date.day, 7),
                              duration_seconds: minutes * 60, impact: "Parada no planificada",
                              reason: reason, production_state: "Estado", created_at: at,
                              source_row: source.tpt_events.size + 1, source_fingerprint: SecureRandom.hex)
  end

  def add_report(date, turno, at:, sacks:, hours: 1)
    fields = EnvasadoraReport::SILOS.values.flat_map { |silo| silo[:readings] }.index_with(10)
    EnvasadoraReport.create!(fields.merge(date: date, turno: turno, created_at: at, author_email: "test@msindustrial.cl",
                                         prodhaver: sacks, horas_haver: hours, sacos_rotos_haver: 0,
                                         sacos_descartados_haver: 0, sacos_no_reconocidos_haver: 0))
  end
end
