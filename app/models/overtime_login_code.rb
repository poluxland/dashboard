require "openssl"

class OvertimeLoginCode < ApplicationRecord
  VALID_FOR = 10.minutes
  RESEND_AFTER = 1.minute
  MAX_ATTEMPTS = 5

  def self.issue(email)
    return unless OvertimeAccess.external?(email)

    now = Time.current
    code = SecureRandom.random_number(1_000_000).to_s.rjust(6, "0")
    challenge = SecureRandom.uuid
    record = find_or_create_by!(email: email) do |row|
      row.assign_attributes(challenge: challenge, digest: sign(email, challenge, code), issued_at: now)
    end
    return [challenge, code] if record.previously_new_record?

    record.with_lock do
      return if record.issued_at > now - RESEND_AFTER

      record.update!(challenge: challenge, digest: sign(email, challenge, code), issued_at: now, attempts: 0, used_at: nil)
      [challenge, code]
    end
  end

  def self.consume(email:, challenge:, code:)
    return false unless OvertimeAccess.external?(email) && code.match?(/\A\d{6}\z/)

    record = find_by(email: email)
    return false unless record

    record.with_lock do
      now = Time.current
      next false unless record.challenge == challenge && record.used_at.nil? &&
        record.issued_at > now - VALID_FOR && record.attempts < MAX_ATTEMPTS

      valid = ActiveSupport::SecurityUtils.secure_compare(record.digest, sign(email, challenge, code))
      record.update!(attempts: record.attempts + 1, used_at: valid ? now : nil)
      valid
    end
  end

  def self.sign(email, challenge, code)
    secret = Rails.application.key_generator.generate_key("overtime-review-code", 32)
    OpenSSL::HMAC.hexdigest("SHA256", secret, [email, challenge, code].join(":"))
  end
  private_class_method :sign
end
