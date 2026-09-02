Rails.application.config.x.google_workspace_domain =
  (ENV["GOOGLE_WORKSPACE_DOMAIN"].presence || "msindustrial.cl").strip.downcase

google_client_id = ENV["GOOGLE_CLIENT_ID"].presence
google_client_secret = ENV["GOOGLE_CLIENT_SECRET"].presence

if Rails.env.test?
  google_client_id ||= "test-google-client-id"
  google_client_secret ||= "test-google-client-secret"
end

Rails.application.config.x.google_oauth_configured = google_client_id.present? && google_client_secret.present?

if google_client_id && google_client_secret
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :google_oauth2,
      google_client_id,
      google_client_secret,
      scope: "email,profile",
      hd: Rails.application.config.x.google_workspace_domain,
      prompt: "select_account",
      access_type: "online",
      overridable_authorize_options: []
  end
else
  Rails.logger.warn("Google OAuth no está configurado: faltan GOOGLE_CLIENT_ID y GOOGLE_CLIENT_SECRET")
end

OmniAuth.config.test_mode = Rails.env.test?
