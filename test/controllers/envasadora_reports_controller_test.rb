require "test_helper"

class EnvasadoraReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @attributes = EnvasadoraReport::SILOS.values.flat_map { |s| s[:readings] }.index_with { 10 }.merge(date: Date.current, turno: "TM", silo19_cement: "HPM")
  end

  test "historic snapshots retain source values and cannot be edited or emailed" do
    sign_in_with_google
    report = EnvasadoraReport.create!(@attributes.merge(author_email: "usuario@msindustrial.cl", source_filename: "history.xlsx", source_row: 3, source_fingerprint: "history-controller", source_data: { sheet: "Sheet1", cells: { "Com. Haver" => "Dato histórico <script>bad()</script>" }, issues: [], present_fields: [], invalid_fields: [] }))
    get envasadora_report_path(report)
    assert_response :success
    assert_select "h1", "Reporte envasadora · Histórico"
    assert_select "button", text: "Enviar reporte por correo", count: 0
    assert_select "script", text: /bad\(\)/, count: 0
    assert_includes response.body, "Dato histórico &lt;script&gt;bad()&lt;/script&gt;"
    get edit_envasadora_report_path(report)
    assert_redirected_to envasadora_report_path(report)
    patch envasadora_report_path(report), params: { envasadora_report: { prodhaver: 999 } }
    assert_redirected_to envasadora_report_path(report)
    assert_equal 0, report.reload.prodhaver
    assert_no_difference("ActionMailer::Base.deliveries.size") { post send_email_envasadora_report_path(report) }
    assert_redirected_to envasadora_report_path(report)
    assert_nil report.reload.sent_at
  end

  test "authentication required" do
    get envasadora_reports_path
    assert_redirected_to login_path
  end

  test "form defaults save preview and email use selected cement and exact record" do
    sign_in_with_google
    get new_envasadora_report_path
    assert_response :success
    assert_select 'select[name="envasadora_report[silo19_cement]"] option[selected]', text: "Extra"
    assert_difference "EnvasadoraReport.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        post envasadora_reports_path, params: { envasadora_report: @attributes.merge(author_email: "forged@example.com", sent_at: Time.current) }
      end
    end
    report = EnvasadoraReport.last
    assert_equal "usuario@msindustrial.cl", report.author_email
    assert_nil report.sent_at
    follow_redirect!
    assert_response :success
    assert_select "h1", "Reporte envasadora"
    another = EnvasadoraReport.create!(@attributes.merge(silo19_cement: "Extra", author_email: report.author_email))
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      post send_email_envasadora_report_path(report)
    end
    mail = ActionMailer::Base.deliveries.last
    assert_includes mail.text_part.decoded, "19 (HPM)"
    assert_includes mail.html_part.decoded, "HPM"
    assert_includes mail.html_part.decoded, "2.000"
    assert_includes mail.text_part.decoded, "2.000"
    assert_not_includes mail.html_part.decoded, "2000,00"
    assert report.reload.sent_at
    assert_nil another.reload.sent_at
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      post send_email_envasadora_report_path(report)
    end
    get envasadora_reports_path
    assert_response :success
  end

  test "invalid measurements rerender without saving or sending" do
    sign_in_with_google
    assert_no_difference [ "EnvasadoraReport.count", "ActionMailer::Base.deliveries.size" ] do
      post envasadora_reports_path, params: { envasadora_report: @attributes.merge(silo19a: "") }
    end
    assert_response :unprocessable_entity
  end

  test "form limits all production hours and server rejects overlong shifts" do
    sign_in_with_google
    get new_envasadora_report_path
    EnvasadoraReport::HOUR_FIELDS.each do |field|
      assert_select "input[name='envasadora_report[#{field}]'][min='0'][max='8'][step='0.01']", count: 1
    end
    assert_no_difference("EnvasadoraReport.count") do
      post envasadora_reports_path, params: { envasadora_report: @attributes.merge(date: "2026-10-26", horas_haver: "65") }
    end
    assert_response :unprocessable_entity
    assert_select ".alert-danger"
    assert_no_difference("EnvasadoraReport.count") do
      post envasadora_reports_path, params: { envasadora_report: @attributes.merge(date: "2026-10-31", turno: "TM", horas_vento: "6.5") }
    end
    assert_response :unprocessable_entity
    assert_select "input[name='envasadora_report[horas_vento]'][max='6']", count: 1
  end

  test "corrected historical hours recalculate the displayed hourly tonnage" do
    sign_in_with_google
    report = EnvasadoraReport.new(@attributes.merge(date: "2026-10-26", turno: "TT", author_email: "Histórico Excel", prodhaver: 14808, horas_haver: 65, source_fingerprint: "corrected-rate", source_data: { "present_fields" => %w[prodhaver horas_haver], "invalid_fields" => [ "horas_haver" ], "cells" => { "Horas Haver" => "65.0", "Haver Ton/h" => "5.7" } }))
    report.save!(validate: false)
    report.correct_historical_hours!("horas_haver", "6.5", reason: "Corrección solicitada")
    get envasadora_report_path(report)
    assert_response :success
    assert_select "tr", text: /Horas Haver.*6,5.*Original: 65.0/
    assert_select "tr", text: /Haver Ton\/h.*56,95.*Recalculado.*Original: 5.7/
  end

  test "author can correct a draft but sent reports and other authors are protected" do
    sign_in_with_google
    report = EnvasadoraReport.create!(@attributes.merge(author_email: "usuario@msindustrial.cl"))
    get edit_envasadora_report_path(report)
    assert_response :success
    patch envasadora_report_path(report), params: { envasadora_report: { silo19_cement: "Ultra" } }
    assert_equal "Ultra", report.reload.silo19_cement
    report.update!(sent_at: Time.current)
    patch envasadora_report_path(report), params: { envasadora_report: { silo19_cement: "Extra" } }
    assert_equal "Ultra", report.reload.silo19_cement
    report.update!(sent_at: nil, author_email: "other@msindustrial.cl")
    patch envasadora_report_path(report), params: { envasadora_report: { silo19_cement: "Extra" } }
    assert_equal "Ultra", report.reload.silo19_cement
  end

  test "only author can send" do
    report = EnvasadoraReport.create!(@attributes.merge(author_email: "another@msindustrial.cl"))
    sign_in_with_google
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      post send_email_envasadora_report_path(report)
    end
    assert_nil report.reload.sent_at
  end
end
