require "rails_helper"

RSpec.describe SalaryAnalytics do
  let(:eng) { create(:department, name: "Engineering") }
  let(:ops) { create(:department, name: "Operations") }
  let(:dev) { create(:job_title, department: eng, name: "Developer") }
  let(:lead) { create(:job_title, department: eng, name: "Lead") }
  let(:analyst) { create(:job_title, department: ops, name: "Analyst") }

  before do
    # US Engineering: 60k and 100k developers, 200k lead. India Operations: 4.16M INR = 50k.
    create(:employee, department: eng, job_title: dev, salary_amount: 60_000)
    create(:employee, department: eng, job_title: dev, salary_amount: 100_000)
    create(:employee, department: eng, job_title: lead, salary_amount: 200_000)
    create(:employee, department: ops, job_title: analyst, country_code: "IN", currency: "INR", salary_amount: 4_160_000)
  end

  describe "#summary" do
    it "calculates count, total, average, median and spread in USD" do
      expect(described_class.new.summary).to include(
        employee_count: 4, total_cost: 410_000.0, average: 102_500.0, median: 80_000.0,
        lowest: 50_000.0, highest: 200_000.0, country_count: 2, department_count: 2
      )
    end

    it "interpolates the median for an even headcount (average of the middle two)" do
      expect(described_class.new(department_id: eng.id).summary[:median]).to eq(100_000.0)
      expect(described_class.new.summary[:median]).to eq(80_000.0) # (60k + 100k) / 2
    end

    it "returns zeros for an empty selection instead of failing" do
      summary = described_class.new(country_code: "JP").summary
      expect(summary).to include(employee_count: 0, total_cost: 0.0, average: 0.0, median: 0.0)
    end
  end

  describe "filters" do
    it "filters by country" do
      expect(described_class.new(country_code: "in").summary[:employee_count]).to eq(1)
    end

    it "filters by department" do
      expect(described_class.new(department_id: ops.id).summary[:total_cost]).to eq(50_000.0)
    end

    it "filters by job title" do
      expect(described_class.new(job_title_id: dev.id).summary).to include(employee_count: 2, average: 80_000.0)
    end

    it "combines filters" do
      summary = described_class.new(country_code: "US", department_id: eng.id, job_title_id: lead.id).summary
      expect(summary).to include(employee_count: 1, average: 200_000.0)
    end
  end

  describe "breakdowns" do
    it "groups by country, department and job title, highest average first" do
      by_country = described_class.new.by_country
      expect(by_country.map { |r| [r[:key], r[:employee_count], r[:average]] }).to eq([["US", 3, 120_000.0], ["IN", 1, 50_000.0]])
      expect(described_class.new.by_department.map { |r| r[:name] }).to eq(%w[Engineering Operations])
      expect(described_class.new.by_job_title.map { |r| r[:name] }).to eq(%w[Lead Developer Analyst])
    end
  end
end
