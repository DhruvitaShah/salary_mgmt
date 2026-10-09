class ApplicationController < ActionController::API
  include ActionController::Cookies

  IDLE_TIMEOUT = 60.minutes
  MAX_SESSION_AGE = 12.hours
  XSRF_COOKIE = "XSRF-TOKEN".freeze
  XSRF_HEADER = "X-XSRF-TOKEN".freeze

  # Handlers declared later win, so the catch-all is first.
  rescue_from StandardError, with: :internal_error unless Rails.env.local?
  rescue_from Currency::MissingRate, Currency::StaleRates, with: :exchange_rate_problem
  rescue_from ActiveRecord::RecordNotUnique, with: :conflict
  rescue_from ActionController::ParameterMissing, with: :bad_request
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  before_action :require_login
  before_action :verify_xsrf_token

  private

  # ---- authentication ----

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = user_from_session
  end

  def user_from_session
    id = request.session[:user_id]
    return nil unless id

    now = Time.current.to_i
    expired = now - request.session[:last_seen_at].to_i > IDLE_TIMEOUT ||
              now - request.session[:signed_in_at].to_i > MAX_SESSION_AGE
    user = User.find_by(id: id) unless expired
    if user.nil?
      request.reset_session
      return nil
    end

    request.session[:last_seen_at] = now # sliding idle timeout
    user
  end

  def sign_in(user)
    request.reset_session # new session id on login prevents session fixation
    now = Time.current.to_i
    token = SecureRandom.hex(32)
    request.session[:user_id] = user.id
    request.session[:signed_in_at] = now
    request.session[:last_seen_at] = now
    request.session[:xsrf_token] = token
    # Readable by the Angular app, which echoes it back in the X-XSRF-TOKEN header.
    cookies[XSRF_COOKIE] = { value: token, httponly: false, same_site: :lax, secure: secure_cookies? }
    @current_user = user
  end

  def sign_out
    request.reset_session
    cookies.delete(XSRF_COOKIE)
    @current_user = nil
  end

  def secure_cookies? = Rails.env.production? && ENV.fetch("FORCE_SSL", "true") == "true"

  def require_login
    render_error(:unauthorized, "unauthorized", "Please sign in to continue.") unless current_user
  end

  # Double-submit token: state-changing requests must echo the token that was
  # issued at login. A malicious site cannot read our cookie to forge the header.
  def verify_xsrf_token
    return if request.get? || request.head? || request.options?

    expected = request.session[:xsrf_token].to_s
    provided = request.headers[XSRF_HEADER].to_s
    return if expected.present? && ActiveSupport::SecurityUtils.secure_compare(expected, provided)

    render_error(:forbidden, "invalid_token", "Your session is out of date. Refresh the page and try again.")
  end

  # ---- errors ----

  def render_error(status, code, message, details = nil)
    body = { error: { code: code, message: message } }
    body[:error][:details] = details if details
    render json: body, status: status
  end

  def not_found(_error = nil) = render_error(:not_found, "not_found", "The record you asked for does not exist.")

  def bad_request(error) = render_error(:bad_request, "bad_request", error.message)

  def conflict(_error = nil)
    render_error(:conflict, "conflict", "That employee ID or email is already in use.")
  end

  def unprocessable(error)
    render_error(:unprocessable_entity, "validation_failed", "Some fields need attention.", error.record.errors.to_hash)
  end

  # The data cannot be reported on reliably yet; say exactly why instead of guessing.
  def exchange_rate_problem(error)
    render_error(:service_unavailable, "exchange_rate_problem", error.message)
  end

  def internal_error(error)
    Rails.logger.error("#{error.class}: #{error.message}\n#{error.backtrace&.first(10)&.join("\n")}")
    render_error(:internal_server_error, "internal_error", "Something went wrong on our side. Please try again.")
  end
end
