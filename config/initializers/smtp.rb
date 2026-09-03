if Rails.env.production?
  Rails.application.config.action_mailer.tap do |mailer|
    mailer.delivery_method = :smtp
    mailer.perform_deliveries = true
    mailer.raise_delivery_errors = true
    mailer.smtp_settings = {
      address: "smtp.gmail.com",
      port: 587,
      domain: "gmail.com",
      user_name: ENV.fetch("GMAIL_ADDRESS"),
      password: ENV.fetch("GMAIL_APP_PASSWORD"),
      authentication: :plain,
      enable_starttls_auto: true
    }
  end
end
