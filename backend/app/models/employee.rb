class Employee < ApplicationRecord
  CODE_FORMAT = /\A[A-Z0-9][A-Z0-9-]{2,19}\z/

  belongs_to :department
  belongs_to :job_title

  normalizes :name, with: ->(v) { v.to_s.squish }
  normalizes :email, with: ->(v) { v.to_s.strip.downcase }
  normalizes :employee_code, with: ->(v) { v.to_s.strip.upcase }
  normalizes :currency, with: ->(v) { v.to_s.strip.upcase }
  normalizes :country_code, with: ->(v) { v.to_s.strip.upcase }

  before_validation :compute_salary_usd

  validates :name, presence: true, length: { minimum: 2, maximum: 80 }
  validates :employee_code, presence: true, format: { with: CODE_FORMAT, message: "must be 3-20 letters, numbers or dashes" },
                            uniqueness: true
  validates :email, presence: true, length: { maximum: 254 },
                    format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true },
                    uniqueness: { case_sensitive: false }
  validates :country_code, inclusion: { in: ->(_) { Country.codes }, message: "is not a supported country" }
  validates :currency, inclusion: { in: ->(_) { Currency.codes }, message: "is not a supported currency" }
  validates :salary_amount, numericality: { greater_than: 0 }
  validate :job_title_belongs_to_department

  def country_name = Country.name_for(country_code)

  private

  def compute_salary_usd
    return unless salary_amount.present? && salary_amount.positive? && Currency.valid?(currency)

    self.salary_usd = Currency.to_usd(salary_amount, currency)
  end

  def job_title_belongs_to_department
    return if job_title.nil? || department.nil?

    errors.add(:job_title, "does not belong to the selected department") if job_title.department_id != department_id
  end
end
