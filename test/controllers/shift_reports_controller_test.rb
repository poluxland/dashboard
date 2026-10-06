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
    assert_select "img[alt='Logo Impromaq']"
    assert_includes response.body, "Impromaq Ltda."
    assert_not_includes response.body, "MS Industrial"
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
    assert_includes mail.html_part.body.decoded, "Impromaq Ltda."
    assert_includes mail.text_part.body.decoded, "Impromaq Ltda."
    assert_not_includes mail.html_part.body.decoded, "MS Industrial"
    assert_not_includes mail.text_part.body.decoded, "MS Industrial"
    logo = mail.attachments["impromaq-logo.png"]
    assert logo.inline?
    assert_equal File.binread(Rails.root.join("app/assets/images/impromaq-logo.png")), logo.body.decoded
    assert_includes mail.html_part.body.decoded, "cid:#{logo.cid}"
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

  test "availability is managed independently and applies to area and individual selection" do
    create_report
    original = ShiftReport.last
    patch person_path(@person), params: { person: { shift_report_enabled: "0" } }
    assert_not @person.reload.shift_report_enabled?
    assert @person.indicator_enabled?
    get new_shift_report_path
    assert_response :success
    assert_select "input[value='#{@person.id}']", count: 0
    assert_select "option", text: "Molienda", count: 0
    assert_no_difference("ShiftReport.count") { create_report }
    assert_response :unprocessable_entity
    assert_equal @person.name, original.reload.participants.first["name"]
    patch person_path(@person), params: { person: { shift_report_enabled: "1" } }
    get new_shift_report_path
    assert_select "input[value='#{@person.id}']", count: 1
    assert_difference("ShiftReport.count") { create_report }
  end

  test "optional observations are saved and safely included in page and both email formats" do
    notes = "Entrega coordinada.\n<b>Comentario literal</b>"
    create_report(observations: notes)
    report = ShiftReport.last
    assert_equal notes, report.observations
    get shift_report_path(report)
    assert_select "h2", "Observaciones"
    assert_includes response.body, "&lt;b&gt;Comentario literal&lt;/b&gt;"
    mail = ShiftReportMailer.closing_report(report)
    assert_includes mail.html_part.body.decoded, "Entrega coordinada."
    assert_includes mail.html_part.body.decoded, "&lt;b&gt;Comentario literal&lt;/b&gt;"
    assert_includes mail.text_part.body.decoded, notes
  end

  test "blank observations are optional and omitted from report and email" do
    get new_shift_report_path
    assert_select "textarea[name='shift_report[observations]']"
    assert_select "textarea[name='shift_report[observations]'][required]", count: 0
    [ nil, "", "  " ].each do |notes|
      assert_difference("ShiftReport.count") { create_report(observations: notes) }
      report = ShiftReport.last
      get shift_report_path(report)
      assert_select "h2", text: "Observaciones", count: 0
      mail = ShiftReportMailer.closing_report(report)
      assert_not_includes mail.html_part.body.decoded, "Observaciones"
      assert_not_includes mail.text_part.body.decoded, "Observaciones"
    end
  end

  test "observations survive form validation errors" do
    create_report(observations: "Conservar comentario", confirmed: "0")
    assert_response :unprocessable_entity
    assert_select "textarea[name='shift_report[observations]']", "Conservar comentario"
  end

  private

  def create_report(**changes)
    post shift_reports_path, params: { shift_report: {
      date: "2026-10-02", shift: "Día 08:00–20:00", confirmed: "1", person_ids: [ @person.id.to_s ]
    }.merge(changes) }
  end
end
