# Aggregations behind the dashboard and Salary Insights. Everything is computed
# in PostgreSQL over the stored USD-equivalent salary, so results are
# deterministic and fast for 10,000+ employees.
class SalaryAnalytics
  BIN_WIDTH = 20_000
  BIN_COUNT = 13 # $0-20k ... $240-260k, last bin is "$240k and above"

  AGGREGATES = <<~SQL.squish.freeze
    COUNT(*) AS employee_count,
    SUM(employees.salary_usd) AS total_cost,
    AVG(employees.salary_usd) AS average,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY employees.salary_usd) AS median,
    MIN(employees.salary_usd) AS lowest,
    MAX(employees.salary_usd) AS highest
  SQL

  # Raises Currency::MissingRate / Currency::StaleRates rather than return
  # numbers that silently leave employees out or use outdated rates.
  def initialize(country_code: nil, department_id: nil, job_title_id: nil)
    scope = Employee.all
    scope = scope.where(country_code: country_code.to_s.upcase) if country_code.present?
    scope = scope.where(department_id: department_id) if department_id.present?
    scope = scope.where(job_title_id: job_title_id) if job_title_id.present?
    @scope = scope
  end

  def summary
    row = @scope.select(
      AGGREGATES,
      "COUNT(DISTINCT employees.country_code) AS country_count",
      "COUNT(DISTINCT employees.department_id) AS department_count"
    ).take
    metrics(row).merge(
      country_count: row.country_count.to_i,
      department_count: row.department_count.to_i
    )
  end

  def by_country
    rows = @scope.group("employees.country_code").select("employees.country_code AS key", AGGREGATES)
    sort_by_average(rows.map { |r| metrics(r).merge(key: r.key, name: Country.name_for(r.key), currency: Country.find(r.key)&.currency) })
  end

  def by_department
    rows = @scope.joins(:department).group("departments.id", "departments.name")
                 .select("departments.id AS key", "departments.name AS label", AGGREGATES)
    sort_by_average(rows.map { |r| metrics(r).merge(key: r.key, name: r.label) })
  end

  def by_job_title
    rows = @scope.joins(job_title: :department).group("job_titles.id", "job_titles.name", "departments.name")
                 .select("job_titles.id AS key", "job_titles.name AS label", "departments.name AS department_name", AGGREGATES)
    sort_by_average(rows.map { |r| metrics(r).merge(key: r.key, name: r.label, department: r.department_name) })
  end

  # Cells for the country x department grid (client pivots them).
  def matrix
    rows = @scope.group("employees.country_code", "employees.department_id")
                 .select("employees.country_code AS country_code", "employees.department_id AS department_id",
                         "COUNT(*) AS employee_count", "SUM(employees.salary_usd) AS total_cost", "AVG(employees.salary_usd) AS average")
    rows.map do |r|
      { country_code: r.country_code, department_id: r.department_id, employee_count: r.employee_count.to_i,
        total_cost: money(r.total_cost), average: money(r.average) }
    end
  end

  def distribution
    last = BIN_COUNT - 1
    counts = @scope.group(Arel.sql("LEAST(FLOOR(employees.salary_usd / #{BIN_WIDTH}), #{last})::int")).count
    bins = Array.new(BIN_COUNT) do |i|
      { from: i * BIN_WIDTH, to: i == last ? nil : (i + 1) * BIN_WIDTH, employee_count: counts[i].to_i }
    end
    pct = @scope.select(
      "MIN(employees.salary_usd) AS lowest", "MAX(employees.salary_usd) AS highest",
      "PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY employees.salary_usd) AS p25",
      "PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY employees.salary_usd) AS p50",
      "PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY employees.salary_usd) AS p75",
      "PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY employees.salary_usd) AS p90"
    ).take
    {
      bin_width: BIN_WIDTH,
      bins: bins,
      percentiles: { lowest: money(pct.lowest), p25: money(pct.p25), median: money(pct.p50),
                     p75: money(pct.p75), p90: money(pct.p90), highest: money(pct.highest) }
    }
  end

  private

  def metrics(row)
    {
      employee_count: row.employee_count.to_i,
      total_cost: money(row.total_cost),
      average: money(row.average),
      median: money(row.median),
      lowest: money(row.lowest),
      highest: money(row.highest)
    }
  end

  def money(value) = value.nil? ? 0.0 : value.to_f.round(2)

  def sort_by_average(rows) = rows.sort_by { |r| -r[:average] }
end
