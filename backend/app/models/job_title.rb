class JobTitle < ApplicationRecord
  belongs_to :department
  has_many :employees, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :department_id }
end
