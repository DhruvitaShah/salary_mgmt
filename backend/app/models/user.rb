class User < ApplicationRecord
  MAX_FAILED_ATTEMPTS = 5
  LOCK_DURATION = 15.minutes
  MIN_PASSWORD_LENGTH = 12

  has_secure_password

  normalizes :email, with: ->(v) { v.to_s.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true },
                    uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: MIN_PASSWORD_LENGTH }, if: -> { password.present? }

  def locked? = locked_until.present? && locked_until.future?

  def minutes_until_unlock = locked? ? ((locked_until - Time.current) / 60.0).ceil : 0

  # After MAX_FAILED_ATTEMPTS wrong passwords the account is locked for LOCK_DURATION.
  def register_failed_attempt!
    attempts = failed_attempts + 1
    if attempts >= MAX_FAILED_ATTEMPTS
      update!(failed_attempts: 0, locked_until: LOCK_DURATION.from_now)
    else
      update!(failed_attempts: attempts)
    end
  end

  def register_successful_sign_in!
    update!(failed_attempts: 0, locked_until: nil, last_sign_in_at: Time.current)
  end
end
