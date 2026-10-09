require "rails_helper"

RSpec.describe SeedData::Generator do
  it "creates valid, unique, deterministic employees" do
    described_class.new(count: 60, seed: 42).call
    expect(Employee.count).to eq(60)
    expect(Employee.distinct.count(:email)).to eq(60)

    # insert_all skips validations, so prove the generated rows satisfy them.
    invalid = Employee.includes(:department, :job_title).reject(&:valid?)
    expect(invalid).to be_empty

    first_run = Employee.order(:employee_code).pluck(:name, :salary_amount)
    Employee.destroy_all
    described_class.new(count: 60, seed: 42).call
    expect(Employee.order(:employee_code).pluck(:name, :salary_amount)).to eq(first_run)
  end
end
