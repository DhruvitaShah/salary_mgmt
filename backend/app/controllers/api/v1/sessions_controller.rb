module Api
  module V1
    # Sign in, sign out, and "who am I" for the single HR user.
    class SessionsController < ApplicationController
      # Login has no session or token yet. Logging out is harmless to force
      # (worst case: the user signs in again), so it needs neither check.
      skip_before_action :require_login, only: %i[create destroy]
      skip_before_action :verify_xsrf_token, only: %i[create destroy]

      INVALID_LOGIN = "The email or password is incorrect.".freeze

      def show
        render json: { data: user_json(current_user) }
      end

      def create
        email = params[:email].to_s
        password = params[:password].to_s
        user = User.find_by(email: email)

        if user&.locked?
          return render_error(:too_many_requests, "account_locked",
                              "Too many failed attempts. Try again in #{user.minutes_until_unlock} minutes.")
        end

        # authenticate_by does the same amount of work whether or not the email
        # exists, so response time does not reveal which emails are registered.
        authenticated = password.present? ? User.authenticate_by(email: email, password: password) : nil
        if authenticated
          authenticated.register_successful_sign_in!
          sign_in(authenticated)
          render json: { data: user_json(authenticated) }
        else
          user&.register_failed_attempt!
          render_error(:unauthorized, "invalid_credentials", INVALID_LOGIN)
        end
      end

      def destroy
        sign_out
        head :no_content
      end

      private

      def user_json(user) = { id: user.id, email: user.email, name: user.name }
    end
  end
end
