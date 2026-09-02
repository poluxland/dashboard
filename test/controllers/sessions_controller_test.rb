require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "redirects unauthenticated users to login" do
    get ots_url

    assert_redirected_to login_url
  end

  test "shows Google login" do
    get login_url

    assert_response :success
    assert_select "form[action='/auth/google_oauth2'][method='post']"
    assert_select ".login-domain", text: /@msindustrial\.cl/
  end

  test "signs in a verified Workspace account and returns to requested page" do
    get ots_url
    assert_redirected_to login_url

    sign_in_with_google(email: "jose.jerez@msindustrial.cl")

    assert_redirected_to ots_url
    follow_redirect!
    assert_response :success
    assert_select ".navbar-text", text: "jose.jerez@msindustrial.cl"
  end

  test "rejects an account from another Workspace domain" do
    sign_in_with_google(
      email: "persona@gmail.com",
      hosted_domain: "gmail.com"
    )

    assert_redirected_to login_url
    follow_redirect!
    assert_select ".alert-danger", text: /@msindustrial\.cl/
  end

  test "rejects an unverified account" do
    sign_in_with_google(email_verified: false)

    assert_redirected_to login_url
  end

  test "expires a session after twelve hours" do
    sign_in_with_google

    travel 13.hours do
      get root_url
      assert_redirected_to login_url
    end
  end

  test "signs out" do
    sign_in_with_google

    delete logout_url

    assert_redirected_to login_url
    get root_url
    assert_redirected_to login_url
  end
end
