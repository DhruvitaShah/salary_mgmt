require "rails_helper"

RSpec.describe "Dashboard, lookups and insights", type: :request do
  before { sign_in }

  let(:eng) { create(:department, name: "Engineering") }
  let(:ops) { create(:department, name: "Operations") }
  let(:dev) { create(:job_title, department: eng, name: "Developer") }
  let(:analyst) { create(:job_title, department: ops, name: "Analyst") }

  before do
    # US engineering: 60k, 100k, 200k   (avg 120k, median 100k)
    [60_000, 100_000, 200_000].each { |s| create(:employee, department: eng, job_title: dev, salary_amount: s) }
    # India operations: 4.16M INR = $50k, 8.32M INR = $100k
    [4_160_000, 8_320_000].each { |s| create(:employee, department: ops, job_title: analyst, country_code: "IN", currency: "INR", salary_amount: s) }
  end

  it "serves lookups" do
    get "/api/v1/lookups"
    expect(response).to have_http_status(:ok)
    expect(json[:countries].map { |c| c[:code] }).to include("US", "IN")
    expect(json[:currencies]).to include(code: "INR", rate_per_usd: 83.2)
    expect(json[:departments].find { |d| d[:name] == "Engineering" }[:job_titles].map { |j| j[:name] }).to eq(["Developer"])
  end

  it "summarises the organisation on the dashboard" do
    get "/api/v1/dashboard"
    expect(json[:summary]).to include(employee_count: 5, country_count: 2, department_count: 2,
                                      total_cost: 510_000.0, average: 102_000.0, median: 100_000.0)
    expect(json[:by_country].map { |c| c[:key] }).to eq(%w[US IN]) # sorted by average, high to low
    expect(json[:by_department].map { |d| d[:name] }).to eq(%w[Engineering Operations])
  end

  it "reports average and median by country, using USD equivalents" do
    get "/api/v1/insights/by_country"
    us = json[:data].find { |r| r[:key] == "US" }
    india = json[:data].find { |r| r[:key] == "IN" }
    expect(us).to include(employee_count: 3, average: 120_000.0, median: 100_000.0, total_cost: 360_000.0, name: "United States")
    expect(india).to include(employee_count: 2, average: 75_000.0, median: 75_000.0, lowest: 50_000.0, highest: 100_000.0)
  end

  it "applies country and department filters" do
    get "/api/v1/insights/by_department", params: { country: "IN" }
    expect(json[:data].map { |r| r[:name] }).to eq(["Operations"])
    expect(json[:summary][:employee_count]).to eq(2)

    get "/api/v1/insights/by_country", params: { department_id: eng.id }
    expect(json[:data].map { |r| r[:key] }).to eq(["US"])
  end

  it "reports salary by job title with its department" do
    get "/api/v1/insights/by_job_title"
    expect(json[:data].map { |r| [r[:name], r[:department]] }).to eq([["Developer", "Engineering"], ["Analyst", "Operations"]])
  end

  it "returns country x department cells" do
    get "/api/v1/insights/matrix"
    cell = json[:data].find { |c| c[:country_code] == "US" && c[:department_id] == eng.id }
    expect(cell).to include(employee_count: 3, total_cost: 360_000.0, average: 120_000.0)
    expect(json[:data].size).to eq(2)
  end

  it "returns a salary distribution in $20k bands with percentiles" do
    get "/api/v1/insights/distribution"
    bins = json[:data][:bins]
    expect(bins.size).to eq(13)
    counts = bins.map { |b| b[:employee_count] }
    expect(counts.sum).to eq(5)
    expect(bins[2][:employee_count]).to eq(1) # 50k -> 40-60k
    expect(bins[3][:employee_count]).to eq(1) # 60k -> 60-80k
    expect(bins[5][:employee_count]).to eq(2) # 100k twice -> 100-120k
    expect(bins.last).to include(from: 240_000, to: nil)
    expect(bins[10][:employee_count]).to eq(1) # 200k -> 200-220k
    expect(json[:data][:percentiles]).to include(lowest: 50_000.0, median: 100_000.0, highest: 200_000.0)
  end

  it "filters insights by job title" do
    get "/api/v1/insights/by_country", params: { job_title_id: dev.id }
    expect(json[:summary][:employee_count]).to eq(3)
    expect(json[:data].map { |r| r[:key] }).to eq(["US"])
  end

  describe "when exchange rates cannot be trusted" do
    it "does not affect the employee list, which shows local currency" do
      stub_const("Currency::RATES", Currency::RATES.except("INR"))
      get "/api/v1/employees"
      expect(response).to have_http_status(:ok)
    end
  end

  it "returns zeros rather than failing for an empty selection" do
    get "/api/v1/insights/by_country", params: { country: "JP" }
    expect(response).to have_http_status(:ok)
    expect(json[:data]).to eq([])
    expect(json[:summary]).to include(employee_count: 0, average: 0.0)
  end
end
