module Api
  module V1
    class DashboardsController < ApplicationController
      def show
        analytics = SalaryAnalytics.new
        render json: {
          summary: analytics.summary,
          by_country: analytics.by_country,
          by_department: analytics.by_department
        }
      end
    end
  end
end
