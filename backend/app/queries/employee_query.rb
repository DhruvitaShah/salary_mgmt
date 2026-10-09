# Builds the filtered, sorted, paginated employee list for the directory.
# All work happens in SQL; the browser only ever receives one page.
class EmployeeQuery
  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100

  SORTS = {
    "name" => "employees.name",
    "employee_code" => "employees.employee_code",
    "department" => "departments.name",
    "job_title" => "job_titles.name",
    "country" => "employees.country_code",
    "salary" => "employees.salary_usd"
  }.freeze

  attr_reader :page, :per_page

  def initialize(params)
    @params = params
    @page = [params[:page].to_i, 1].max
    per = params[:per_page].to_i
    @per_page = per.positive? ? [per, MAX_PER_PAGE].min : DEFAULT_PER_PAGE
  end

  def filtered
    scope = Employee.all
    scope = scope.where(country_code: @params[:country].to_s.upcase) if @params[:country].present?
    scope = scope.where(department_id: @params[:department_id]) if @params[:department_id].present?
    scope = scope.where(job_title_id: @params[:job_title_id]) if @params[:job_title_id].present?
    scope = search(scope, @params[:q]) if @params[:q].present?
    scope
  end

  def total = @total ||= filtered.count

  def total_pages = [(total / per_page.to_f).ceil, 1].max

  def records
    filtered
      .eager_load(:department, :job_title)
      .order(order_clause)
      .limit(per_page)
      .offset((page - 1) * per_page)
  end

  private

  def search(scope, q)
    term = "%#{Employee.sanitize_sql_like(q.to_s.strip)}%"
    scope.where("employees.name ILIKE :t OR employees.email ILIKE :t OR employees.employee_code ILIKE :t", t: term)
  end

  def order_clause
    column = SORTS.fetch(@params[:sort].to_s, SORTS["name"])
    direction = @params[:direction].to_s.downcase == "desc" ? "DESC" : "ASC"
    # employees.id is a stable tie-breaker so pages never overlap or skip rows.
    Arel.sql("#{column} #{direction}, employees.id ASC")
  end
end
