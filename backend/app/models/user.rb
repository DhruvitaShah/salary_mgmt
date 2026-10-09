# The HR Manager's login. There is no sign-up: the single account is created
# by HrUserProvisioner (see `bin/rails users:ensure_hr`).
class User < ApplicationRecord
  MIN_PASSWORD_LENGTH = 12

  has_secure_password

  normalizes :email, with: ->(v) { v.to_s.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true },
                    uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: MIN_PASSWORD_LENGTH }, if: -> { password.present? }
end
