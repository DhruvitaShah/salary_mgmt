module AuthHelpers
  PASSWORD = "correct-horse-battery".freeze

  # Logs in through the real endpoint so request specs exercise the cookie session.
  def sign_in(user = create(:user))
    post "/api/v1/session", params: { email: user.email, password: PASSWORD }, as: :json
    expect(response).to have_http_status(:ok)
    user
  end

  # Header the Angular app sends on POST/PATCH/DELETE (double-submit token).
  def xsrf_headers = { "X-XSRF-TOKEN" => cookies["XSRF-TOKEN"] }
end

RSpec.configure { |c| c.include AuthHelpers, type: :request }
