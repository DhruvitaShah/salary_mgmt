module Api
  module V1
    # Filterable salary analysis. Every action accepts ?country=US&department_id=3&job_title_id=12.
    class InsightsController < ApplicationController
      def by_country = render_report(:by_country)
      def by_department = render_report(:by_department)
      def by_job_title = render_report(:by_job_title)
      def matrix = render_report(:matrix)
      def distribution = render_report(:distribution)

      private

      def render_report(name)
        analytics = SalaryAnalytics.new(country_code: params[:country], department_id: params[:department_id],
                                     job_title_id: params[:job_title_id])
        render json: { summary: analytics.summary, data: analytics.public_send(name) }
      end
    end
  end
end
