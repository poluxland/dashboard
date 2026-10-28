require "test_helper"

class EnvasadoraReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @attributes = EnvasadoraReport::SILOS.values.flat_map { |s| s[:readings] }.index_with { 10 }.merge(date: Date.current, turno: "TM", silo19_cement: "HPM")
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
    assert_includes mail.text_part.decoded, "Silo 19 (HPM)"
    assert_includes mail.html_part.decoded, "HPM"
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
