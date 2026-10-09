module Api
  module V1
    # Reference data used to fill filters and forms.
    class LookupsController < ApplicationController
      def show
        render json: {
          countries: Country.all.map { |c| { code: c.code, name: c.name, currency: c.currency } },
          currencies: Currency.codes.map { |code| { code: code, rate_per_usd: Currency.rate(code).to_f } },
          departments: Department.includes(:job_titles).order(:name).map do |d|
            { id: d.id, name: d.name, job_titles: d.job_titles.sort_by(&:name).map { |j| { id: j.id, name: j.name } } }
          end
        }
      end
    end
  end
end
