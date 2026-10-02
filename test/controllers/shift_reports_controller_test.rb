require "test_helper"
require "minitest/mock"

class ShiftReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_with_google
    @person = people(:one)
    @person.update!(area: "Molienda")
  end

  test "roster and people administration show areas" do
    get new_shift_report_path
    assert_response :success
    assert_select "option", "Molienda"
    assert_select "input[data-area='Molienda']"
    get people_path
    assert_response :success
    assert_select "td", "Molienda"
    post people_path, params: { person: { name: "Persona nueva", area: "  Taller  ", planta: "LCA" } }
    assert_redirected_to people_path
    assert_equal "Taller", Person.find_by!(name: "Persona nueva").area
  end

  test "creates immutable roster and uses session identity ignoring forged signature" do
    assert_difference("ShiftReport.count") { create_report(signer_name: "Falso", signer_email: "otro@example.com", person_ids: [ @person.id.to_s, @person.id.to_s ]) }
    report = ShiftReport.last
    assert_equal "Usuario Industrial", report.signer_name
    assert_equal "usuario@msindustrial.cl", report.signer_email
    assert_equal 1, report.participants.size
    original_name = @person.name
    @person.update!(name: "Nombre modificado", area: "Taller")
    assert_equal original_name, report.reload.participants.first["name"]
    assert_equal "Molienda", report.participants.first["area"]
    get shift_report_path(report)
    assert_response :success
    assert_match "sin novedades reportadas", response.body
    get shift_reports_path
    assert_response :success
  end

  test "rejects empty missing stale and unconfirmed rosters" do
    [ { person_ids: [ "" ] }, { person_ids: [ "999999999" ] }, { confirmed: "0" }, { confirmed: nil }, { date: "" }, { shift: "" } ].each do |changes|
      assert_no_difference("ShiftReport.count") { create_report(**changes) }
      assert_response :unprocessable_entity
    end
  end

  test "sending uses fixed recipients and does not duplicate sent email" do
    create_report
    report = ShiftReport.last
    assert_difference("ActionMailer::Base.deliveries.size", 1) do
      post send_email_shift_report_path(report), params: { recipient: "otro@example.com" }
    end
    assert report.reload.sent_at?
    mail = ActionMailer::Base.deliveries.last
    assert_equal ShiftReport::RECIPIENTS, mail.to
    assert_equal [ "usuario@msindustrial.cl" ], mail.reply_to
    assert_includes mail.text_part.body.decoded, @person.name
    assert_includes mail.html_part.body.decoded, "Usuario Industrial"
    assert_no_difference("ActionMailer::Base.deliveries.size") { post send_email_shift_report_path(report) }
  end

  test "delivery failure preserves report for retry" do
    create_report
    report = ShiftReport.last
    failing_mail = Object.new
    def failing_mail.deliver_now
      raise IOError, "SMTP unavailable"
    end
    ShiftReportMailer.stub(:closing_report, failing_mail) do
      post send_email_shift_report_path(report)
    end
    assert_nil report.reload.sent_at
    assert_match "No se pudo confirmar", flash[:alert]
  end

  test "requires authentication and only signer can send" do
    create_report
    report = ShiftReport.last
    sign_in_with_google(email: "otro@msindustrial.cl")
    assert_no_difference("ActionMailer::Base.deliveries.size") { post send_email_shift_report_path(report) }
    assert_nil report.reload.sent_at
    delete logout_path
    get new_shift_report_path
    assert_redirected_to login_path
    assert_no_difference("ShiftReport.count") { create_report }
    assert_redirected_to login_path
    assert_no_difference("ActionMailer::Base.deliveries.size") { post send_email_shift_report_path(report) }
    assert_redirected_to login_path
  end

  private

  def create_report(**changes)
    post shift_reports_path, params: { shift_report: {
      date: "2026-10-02", shift: "Día 08:00–20:00", confirmed: "1", person_ids: [ @person.id.to_s ]
    }.merge(changes) }
  end
end
