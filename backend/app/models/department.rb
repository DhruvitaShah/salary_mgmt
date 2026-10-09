class Department < ApplicationRecord
  has_many :job_titles, dependent: :restrict_with_error
  has_many :employees, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
end
