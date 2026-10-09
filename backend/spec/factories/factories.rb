FactoryBot.define do
  factory :department do
    sequence(:name) { |n| "Department #{n}" }
  end

  factory :job_title do
    department
    sequence(:name) { |n| "Job Title #{n}" }
  end

  factory :employee do
    sequence(:employee_code) { |n| format("ACME-%05d", n) }
    sequence(:name) { |n| "Person #{n}" }
    sequence(:email) { |n| "person#{n}@acme.com" }
    country_code { "US" }
    currency { "USD" }
    salary_amount { 100_000 }
    department
    job_title { association :job_title, department: department }
  end
end

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "hr#{n}@acme.com" }
    name { "HR Manager" }
    password { AuthHelpers::PASSWORD }
  end
end
