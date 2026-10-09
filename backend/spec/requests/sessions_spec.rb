require "rails_helper"

RSpec.describe "Authentication", type: :request do
  let!(:user) { create(:user, email: "hr@acme.com") }

  def login(email: "hr@acme.com", password: AuthHelpers::PASSWORD)
    post "/api/v1/session", params: { email: email, password: password }, as: :json
  end

  describe "POST /api/v1/session" do
    it "signs in with the right credentials and returns the user without secrets" do
      login
      expect(response).to have_http_status(:ok)
      expect(json[:data]).to eq(id: user.id, email: "hr@acme.com", name: "HR Manager")
      expect(response.body).not_to include("password")
      expect(cookies["XSRF-TOKEN"]).to be_present
    end

    it "ignores email case and surrounding spaces" do
      login(email: "  HR@Acme.com ")
      expect(response).to have_http_status(:ok)
    end

    it "gives the same message for a wrong password and an unknown email" do
      login(password: "wrong-password-here")
      wrong_password = [response.status, json[:error]]
      login(email: "nobody@acme.com")
      unknown_email = [response.status, json[:error]]
      expect(wrong_password).to eq(unknown_email)
      expect(wrong_password.first).to eq(401)
      expect(json[:error][:code]).to eq("invalid_credentials")
    end

    it "rejects a blank password" do
      login(password: "")
      expect(response).to have_http_status(:unauthorized)
    end

    it "locks the account after 5 failed attempts, even for the right password" do
      5.times { login(password: "wrong-password-here") }
      login
      expect(response).to have_http_status(:too_many_requests)
      expect(json[:error][:code]).to eq("account_locked")
      expect(json[:error][:message]).to match(/15 minutes/)
    end

    it "allows sign-in again after the lock expires" do
      5.times { login(password: "wrong-password-here") }
      travel_to(16.minutes.from_now) do
        login
        expect(response).to have_http_status(:ok)
      end
    end

    it "resets the failed-attempt counter after a successful sign-in" do
      4.times { login(password: "wrong-password-here") }
      login
      expect(user.reload.failed_attempts).to eq(0)
    end
  end

  describe "GET /api/v1/session" do
    it "is 401 when signed out" do
      get "/api/v1/session"
      expect(response).to have_http_status(:unauthorized)
      expect(json[:error][:code]).to eq("unauthorized")
    end

    it "returns the current user when signed in" do
      login
      get "/api/v1/session"
      expect(response).to have_http_status(:ok)
      expect(json[:data][:email]).to eq("hr@acme.com")
    end
  end

  describe "DELETE /api/v1/session" do
    it "signs out" do
      login
      delete "/api/v1/session"
      expect(response).to have_http_status(:no_content)
      get "/api/v1/employees"
      expect(response).to have_http_status(:unauthorized)
    end

    it "does not fail when already signed out" do
      delete "/api/v1/session"
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "protected API" do
    [
      [:get, "/api/v1/employees"], [:get, "/api/v1/employees/1"], [:post, "/api/v1/employees"],
      [:patch, "/api/v1/employees/1"], [:get, "/api/v1/lookups"], [:get, "/api/v1/dashboard"],
      [:get, "/api/v1/insights/by_country"], [:get, "/api/v1/insights/matrix"], [:get, "/api/v1/insights/distribution"]
    ].each do |verb, path|
      it "returns 401 for #{verb.to_s.upcase} #{path} without a session" do
        public_send(verb, path, as: :json)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    it "keeps the health check and the app shell public" do
      get "/up"
      expect(response).to have_http_status(:ok)
      get "/"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "session expiry" do
    it "expires after 60 minutes without activity" do
      login
      travel_to(61.minutes.from_now) do
        get "/api/v1/employees"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    it "stays alive while the user keeps working" do
      login
      travel_to(40.minutes.from_now) { get "/api/v1/lookups" }
      travel_to(80.minutes.from_now) do
        get "/api/v1/lookups"
        expect(response).to have_http_status(:ok)
      end
    end

    it "ends after 12 hours no matter what" do
      login
      (1..11).each { |h| travel_to(h.hours.from_now) { get "/api/v1/lookups" } }
      travel_to(11.hours.from_now + 40.minutes) { get "/api/v1/lookups" } # still active, so not an idle timeout
      travel_to(12.hours.from_now + 1.minute) do
        get "/api/v1/lookups"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "CSRF protection for state-changing requests" do
    before { login }

    it "rejects a POST without the token header" do
      post "/api/v1/employees", params: { employee: { name: "X" } }, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json[:error][:code]).to eq("invalid_token")
    end

    it "rejects a wrong token" do
      post "/api/v1/employees", params: { employee: { name: "X" } }, headers: { "X-XSRF-TOKEN" => "nope" }, as: :json
      expect(response).to have_http_status(:forbidden)
    end

    it "lets a request with the right token through to validation" do
      post "/api/v1/employees", params: { employee: { name: "X" } }, headers: xsrf_headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not require the token for reads" do
      get "/api/v1/employees"
      expect(response).to have_http_status(:ok)
    end
  end
end
