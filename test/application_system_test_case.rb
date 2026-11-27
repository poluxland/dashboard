require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  def after_teardown
    session = Capybara.current_session
    session.server&.wait_for_pending_requests
    session.raise_server_error!
  ensure
    # Chrome rejects Capybara's wildcard storage reset. Quit to discard the entire browser session.
    session&.quit
    super
  end
end
