require "test_helper"

class ClinkerTransfersControllerTest < ActionDispatch::IntegrationTest
  test "requires login" do
    get clinker_transfers_path
    assert_redirected_to login_path
  end

  test "registers daily tons rejects duplicates and protects another author" do
    sign_in_with_google
    get clinker_transfers_path
    assert_response :success
    assert_select "h1", "Traslado de clínker · PTM"
    assert_select "canvas", count: 3
    get new_clinker_transfer_path
    assert_response :success
    assert_difference "ClinkerTransfer.count" do
      post clinker_transfers_path, params: { clinker_transfer: { date: Date.current, tons: "1291.5", observations: "Prueba" } }
    end
    record = ClinkerTransfer.last
    assert_equal BigDecimal("1291.5"), record.tons
    assert_redirected_to clinker_transfers_path
    get edit_clinker_transfer_path(record)
    assert_response :success
    patch clinker_transfer_path(record), params: { clinker_transfer: { tons: "1300" } }
    assert_equal 1300, record.reload.tons
    assert_no_difference "ClinkerTransfer.count" do
      post clinker_transfers_path, params: { clinker_transfer: { date: Date.current, tons: "5" } }
    end
    assert_response :unprocessable_entity
    record.update!(author_email: "other@example.com")
    patch clinker_transfer_path(record), params: { clinker_transfer: { tons: "1" } }
    assert_redirected_to clinker_transfers_path
    assert_equal 1300, record.reload.tons
  end
end
