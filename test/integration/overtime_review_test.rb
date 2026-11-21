require "test_helper"

class OvertimeReviewTest < ActionDispatch::IntegrationTest
  EMAIL = "carolina.vera@meloncementos.cl"
  GLOBAL_REVIEW_EMAIL = "joseignaciojerez@gmail.com"

  setup do
    @first = entry("Carolina Vera", "Registro de Carolina")
    @second = entry("Carolina Vera", "Segundo registro de Carolina")
    @other = entry("Johnny Rute", "Registro de otro mandante")
  end

  test "an external reviewer can change several of their own entries and a mixed batch is rejected atomically" do
    get overtime_entries_path
    assert_redirected_to overtime_login_path
    assert_no_difference -> { ActionMailer::Base.deliveries.size } do
      post request_overtime_code_path, params: { email: "usuario@ejemplo.cl" }
    end
    post verify_overtime_code_path, params: { overtime_code: "123456" }
    assert_redirected_to overtime_login_path

    sign_in_for_review
    get overtime_entries_path
    assert_response :success
    assert_select 'input[name="ids[]"]', 2
    assert_includes response.body, @first.descripcion
    assert_not_includes response.body, @other.descripcion

    get new_overtime_entry_path
    assert_response :forbidden

    assert_no_difference "OvertimeReview.count" do
      patch review_overtime_entries_path, params: { ids: [ @first.id, @other.id ], decision: "Aprobada" }
    end
    assert_equal OvertimeEntry::PENDING, @first.reload.estado
    assert_equal OvertimeEntry::PENDING, @other.reload.estado

    assert_difference "OvertimeReview.count", 2 do
      patch review_overtime_entries_path, params: { ids: [ @first.id, @second.id ], decision: "Aprobada" }
    end
    assert_redirected_to overtime_entries_path
    assert_equal [ "Aprobada", "Aprobada" ], [ @first.reload.estado, @second.reload.estado ]
    assert_equal EMAIL, @first.overtime_reviews.last.reviewer_email

    assert_no_difference "OvertimeReview.count" do
      patch review_overtime_entries_path, params: { ids: [ @first.id ], decision: "Rechazada", reason: "Corrección" }
    end
    assert_equal "Aprobada", @first.reload.estado
    get root_path
    assert_redirected_to login_path
  end

  test "the authorized Gmail account can review different mandantes using an emailed code" do
    sign_in_for_review(email: GLOBAL_REVIEW_EMAIL)
    get overtime_entries_path
    assert_response :success
    assert_select 'select[name="mandante"] option', text: "Johnny Rute"
    assert_select 'input[name="ids[]"]', 3

    assert_difference "OvertimeReview.count", 2 do
      patch review_overtime_entries_path, params: { ids: [ @first.id, @other.id ], decision: "Aprobada" }
    end
    assert_equal [ "Aprobada", "Aprobada" ], [ @first.reload.estado, @other.reload.estado ]
    assert_equal GLOBAL_REVIEW_EMAIL, @other.overtime_reviews.last.reviewer_email
    assert_not_includes OvertimeAccess::RECIPIENTS, GLOBAL_REVIEW_EMAIL
  end

  test "corporate login grants overtime review only to the imported list" do
    sign_in_with_google
    get overtime_entries_path
    assert_redirected_to overtime_login_path

    sign_in_with_google(email: "jose.jerez@msindustrial.cl")
    get overtime_entries_path
    assert_response :success
    assert_includes response.body, @other.descripcion
    assert_difference "OvertimeReview.count", 2 do
      patch review_overtime_entries_path, params: { ids: [ @first.id, @other.id ], decision: "Rechazada", reason: "Falta respaldo" }
    end
    assert_equal "Falta respaldo", @other.overtime_reviews.last.reason

    post overtime_entries_path, params: {
      overtime_entry: { fecha: "2026-11-19", descripcion: "Registro nuevo", personal: "Turno", he: "2.5",
                       inicio: "22:30", termino: "01:00", mandante: "Carolina Vera", ep: "Noviembre", estado: "Aprobada" }
    }
    assert_redirected_to overtime_entries_path
    entry = OvertimeEntry.find_by!(descripcion: "Registro nuevo")
    assert_equal "22:30", entry.inicio.strftime("%H:%M")
    assert_equal "01:00", entry.termino.strftime("%H:%M")
    assert_equal "Noviembre", entry.ep
    assert_equal OvertimeEntry::PENDING, entry.estado
  end

  test "a report link keeps the reviewer scope and points to the approval page" do
    email = OvertimeMailer.pending_report(recipient: EMAIL).message
    assert_equal [ EMAIL ], email.to
    assert_includes email.html_part.decoded, "http://example.com/horas"
    assert_includes email.text_part.decoded, @first.descripcion
    assert_not_includes email.html_part.decoded, @other.descripcion
  end

  test "the same slot sends one report per recipient after enablement" do
    scheduled = Time.utc(2026, 11, 21, 11, 30)
    assert_no_difference -> { ActionMailer::Base.deliveries.size } do
      OvertimeReportDelivery.dispatch_due(reference_time: scheduled - 1.minute, start_at: scheduled.iso8601)
    end
    assert_difference -> { ActionMailer::Base.deliveries.size }, 8 do
      2.times { OvertimeReportDelivery.dispatch_due(reference_time: scheduled + 1.minute, start_at: scheduled.iso8601) }
    end
    assert_equal OvertimeAccess::RECIPIENTS.sort, OvertimeReportDelivery.where(scheduled_at: scheduled).where.not(sent_at: nil).pluck(:recipient).sort
  end

  private

  def entry(mandante, description)
    OvertimeEntry.create!(fecha: Date.new(2026, 11, 19), descripcion: description, he: 3, mandante: mandante, estado: OvertimeEntry::PENDING)
  end

  def sign_in_for_review(email: EMAIL)
    assert_difference -> { ActionMailer::Base.deliveries.size }, 1 do
      post request_overtime_code_path, params: { email: email.upcase }
    end
    code = ActionMailer::Base.deliveries.last.body.decoded[/\b\d{6}\b/]
    post verify_overtime_code_path, params: { overtime_code: code }
    assert_redirected_to overtime_entries_path
  end
end
