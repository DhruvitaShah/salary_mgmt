require "rails_helper"

RSpec.describe Employee do
  subject(:employee) { build(:employee) }

  it { is_expected.to be_valid }

  it "normalises name, email, code and currency" do
    e = build(:employee, name: "  Ada   Lovelace ", email: " ADA@Acme.COM ", employee_code: "acme-77", currency: "usd")
    e.validate
    expect([e.name, e.email, e.employee_code, e.currency]).to eq(["Ada Lovelace", "ada@acme.com", "ACME-77", "USD"])
  end

  describe "validations" do
    it "requires a name of at least 2 characters" do
      expect(build(:employee, name: "A")).not_to be_valid
      expect(build(:employee, name: "")).not_to be_valid
    end

    it "requires a well-formed, unique email (case-insensitive)" do
      create(:employee, email: "dup@acme.com")
      expect(build(:employee, email: "DUP@acme.com")).not_to be_valid
      expect(build(:employee, email: "not-an-email")).not_to be_valid
    end

    it "requires a unique employee ID with a valid format" do
      create(:employee, employee_code: "ACME-1")
      expect(build(:employee, employee_code: "acme-1")).not_to be_valid
      expect(build(:employee, employee_code: "a b")).not_to be_valid
    end

    it "requires a supported country and currency" do
      expect(build(:employee, country_code: "ZZ")).not_to be_valid
      expect(build(:employee, currency: "XXX")).not_to be_valid
    end

    it "requires a positive salary" do
      expect(build(:employee, salary_amount: 0)).not_to be_valid
      expect(build(:employee, salary_amount: -5)).not_to be_valid
    end

    it "requires the job title to belong to the department" do
      other = create(:job_title)
      expect(build(:employee, job_title: other)).not_to be_valid
    end
  end

  describe "salary USD equivalent" do
    it "is computed from the fixed rate on validation" do
      e = build(:employee, salary_amount: 8_320_000, currency: "INR", country_code: "IN")
      e.validate
      expect(e.salary_usd).to eq(100_000)
    end

    it "is recomputed when the salary changes" do
      e = create(:employee)
      e.update!(salary_amount: 120_000)
      expect(e.salary_usd).to eq(120_000)
    end
  end
end
