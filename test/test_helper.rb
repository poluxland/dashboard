ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module GoogleAuthenticationTestHelper
  def sign_in_with_google(
    email: "usuario@msindustrial.cl",
    hosted_domain: "msindustrial.cl",
    email_verified: true,
    uid: "google-user-123"
  )
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: uid,
      info: {
        email: email,
        name: "Usuario Industrial",
        email_verified: email_verified
      },
      extra: {
        id_info: {
          "hd" => hosted_domain,
          "email_verified" => email_verified
        }
      }
    )

    get "/auth/google_oauth2/callback"
  end
end

ActionDispatch::IntegrationTest.include(GoogleAuthenticationTestHelper)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
