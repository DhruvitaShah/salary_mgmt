require "rails_helper"

RSpec.describe EmployeeQuery do
  let(:eng) { create(:department, name: "Engineering") }
  let(:dev) { create(:job_title, department: eng, name: "Developer") }
  let(:sales) { create(:department, name: "Sales") }
  let(:rep) { create(:job_title, department: sales, name: "Rep") }

  let!(:ana) { create(:employee, name: "Ana Silva", email: "ana@acme.com", employee_code: "ACME-00001", country_code: "BR", currency: "BRL", salary_amount: 300_000, department: eng, job_title: dev) }
  let!(:bob) { create(:employee, name: "Bob Stone", email: "bob@acme.com", employee_code: "ACME-00002", department: sales, job_title: rep, salary_amount: 90_000) }
  let!(:cy)  { create(:employee, name: "Cy Young", email: "cy@acme.com", employee_code: "ACME-00003", department: eng, job_title: dev, salary_amount: 120_000) }

  def names(params) = described_class.new(ActionController::Parameters.new(params)).records.map(&:name)

  it "searches name, email and employee ID case-insensitively" do
    expect(names(q: "SILVA")).to eq(["Ana Silva"])
    expect(names(q: "bob@")).to eq(["Bob Stone"])
    expect(names(q: "00003")).to eq(["Cy Young"])
  end

  it "treats LIKE wildcards in the search term literally" do
    expect(names(q: "%")).to be_empty
  end

  it "filters by country, department and job title" do
    expect(names(country: "br")).to eq(["Ana Silva"])
    expect(names(department_id: eng.id)).to contain_exactly("Ana Silva", "Cy Young")
    expect(names(job_title_id: rep.id)).to eq(["Bob Stone"])
    expect(names(department_id: eng.id, country: "US")).to eq(["Cy Young"])
  end

  it "sorts by USD-equivalent salary so currencies compare fairly" do
    expect(names(sort: "salary", direction: "asc")).to eq(["Ana Silva", "Bob Stone", "Cy Young"])
    expect(names(sort: "salary", direction: "desc")).to eq(["Cy Young", "Bob Stone", "Ana Silva"])
  end

  it "falls back to name order for unknown sort keys (no SQL injection)" do
    expect(names(sort: "name; DROP TABLE employees")).to eq(["Ana Silva", "Bob Stone", "Cy Young"])
  end

  it "paginates with a stable total" do
    query = described_class.new(ActionController::Parameters.new(page: 2, per_page: 2))
    expect(query.records.map(&:name)).to eq(["Cy Young"])
    expect([query.total, query.total_pages, query.page, query.per_page]).to eq([3, 2, 2, 2])
  end

  it "clamps page size and page number" do
    query = described_class.new(ActionController::Parameters.new(page: -4, per_page: 5000))
    expect([query.page, query.per_page]).to eq([1, described_class::MAX_PER_PAGE])
  end
end
