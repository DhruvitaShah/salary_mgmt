# Turns an Employee into the JSON shape the Angular client expects.
class EmployeeSerializer
  def self.list_item(employee)
    {
      id: employee.id,
      employee_code: employee.employee_code,
      name: employee.name,
      email: employee.email,
      country_code: employee.country_code,
      country_name: employee.country_name,
      department: { id: employee.department_id, name: employee.department.name },
      job_title: { id: employee.job_title_id, name: employee.job_title.name },
      salary_amount: employee.salary_amount.to_f,
      currency: employee.currency,
      salary_usd: employee.salary_usd.to_f
    }
  end

  def self.detail(employee) = list_item(employee)
end
