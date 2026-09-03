class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "control@msindustrial.cl")
  layout "mailer"
end
