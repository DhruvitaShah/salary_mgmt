require "rails_helper"

RSpec.describe "Employees API", type: :request do
  before { sign_in }

  let(:department) { create(:department) }
  let(:job_title) { create(:job_title, department: department) }
  let(:payload) do
    { employee: { employee_code: "ACME-70001", name: "Linus Torvalds", email: "linus@acme.com", country_code: "US",
                  department_id: department.id, job_title_id: job_title.id, salary_amount: 150_000, currency: "USD" } }
  end

  describe "GET /api/v1/employees" do
    before { create_list(:employee, 3, department: department, job_title: job_title) }

    it "returns a page of employees with pagination metadata" do
      get "/api/v1/employees", params: { per_page: 2 }
      expect(response).to have_http_status(:ok)
      expect(json[:data].size).to eq(2)
      expect(json[:meta]).to include(page: 1, per_page: 2, total: 3, total_pages: 2)
      expect(json[:data].first).to include(:employee_code, :name, :email, :country_name, :salary_amount, :currency, :salary_usd)
      expect(json[:data].first[:department]).to include(:id, :name)
    end

    it "filters and searches" do
      create(:employee, name: "Zed Unique", department: department, job_title: job_title)
      get "/api/v1/employees", params: { q: "zed uni" }
      expect(json[:data].map { |e| e[:name] }).to eq(["Zed Unique"])
    end
  end

  describe "query count (no N+1)" do
    it "runs the same number of queries for 3 employees as for 30" do
      create_list(:employee, 3, department: department, job_title: job_title)
      few = count_queries { get "/api/v1/employees", params: { per_page: 100 } }
      create_list(:employee, 27, department: department, job_title: job_title)
      many = count_queries { get "/api/v1/employees", params: { per_page: 100 } }
      expect(json[:data].size).to eq(30)
      expect(many).to eq(few)
    end
  end

  describe "GET /api/v1/employees/:id" do
    it "returns the employee" do
      employee = Employee.create!(payload[:employee])
      get "/api/v1/employees/#{employee.id}"
      expect(response).to have_http_status(:ok)
      expect(json[:data]).to include(name: "Linus Torvalds", salary_amount: 150_000.0, currency: "USD", salary_usd: 150_000.0)
      expect(json[:data]).not_to include(:salary_history)
    end

    it "returns a JSON 404 for unknown ids" do
      get "/api/v1/employees/0"
      expect(response).to have_http_status(:not_found)
      expect(json[:error][:code]).to eq("not_found")
    end
  end

  describe "POST /api/v1/employees" do
    it "creates an employee" do
      expect { post "/api/v1/employees", params: payload, headers: xsrf_headers, as: :json }.to change(Employee, :count).by(1)
      expect(response).to have_http_status(:created)
      expect(json[:data]).to include(employee_code: "ACME-70001", salary_usd: 150_000.0)
    end

    it "returns field errors for invalid input" do
      post "/api/v1/employees", params: { employee: payload[:employee].merge(email: "nope", salary_amount: -1) }, headers: xsrf_headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json[:error][:code]).to eq("validation_failed")
      expect(json[:error][:details]).to include(:email, :salary_amount)
    end

    it "reports duplicate employee IDs" do
      create(:employee, employee_code: "ACME-70001")
      post "/api/v1/employees", params: payload, headers: xsrf_headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json[:error][:details]).to include(:employee_code)
    end

    it "returns 400 when the employee key is missing" do
      post "/api/v1/employees", params: {}, headers: xsrf_headers, as: :json
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "PATCH /api/v1/employees/:id" do
    let!(:employee) { Employee.create!(payload[:employee]) }

    it "updates details" do
      patch "/api/v1/employees/#{employee.id}", params: { employee: { name: "Linus T." } }, headers: xsrf_headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(json[:data][:name]).to eq("Linus T.")
    end

    it "updates the salary and recomputes the USD equivalent" do
      patch "/api/v1/employees/#{employee.id}", params: { employee: { salary_amount: 160_000 } }, headers: xsrf_headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(json[:data]).to include(salary_amount: 160_000.0, salary_usd: 160_000.0)
    end
  end
end
