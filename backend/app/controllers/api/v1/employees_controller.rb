module Api
  module V1
    class EmployeesController < ApplicationController
      def index
        query = EmployeeQuery.new(params)
        render json: {
          data: query.records.map { |e| EmployeeSerializer.list_item(e) },
          meta: { page: query.page, per_page: query.per_page, total: query.total, total_pages: query.total_pages }
        }
      end

      def show
        render json: { data: EmployeeSerializer.detail(find_employee) }
      end

      def create
        employee = Employee.create!(employee_params)
        render json: { data: EmployeeSerializer.detail(employee) }, status: :created
      end

      def update
        employee = find_employee
        employee.update!(employee_params)
        render json: { data: EmployeeSerializer.detail(employee) }
      end

      private

      def find_employee = Employee.includes(:department, :job_title).find(params[:id])

      def employee_params
        params.require(:employee).permit(
          :employee_code, :name, :email, :country_code, :department_id, :job_title_id,
          :salary_amount, :currency
        )
      end
    end
  end
end
