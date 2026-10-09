export interface Country { code: string; name: string; currency: string }
export interface CurrencyRate { code: string; rate_per_usd: number }
export interface JobTitleRef { id: number; name: string }
export interface DepartmentLookup { id: number; name: string; job_titles: JobTitleRef[] }

export interface Lookups {
  countries: Country[];
  currencies: CurrencyRate[];
  departments: DepartmentLookup[];
  salary_limits_usd: { min: number; max: number };
}

export interface Employee {
  id: number;
  employee_code: string;
  name: string;
  email: string;
  country_code: string;
  country_name: string;
  department: { id: number; name: string };
  job_title: { id: number; name: string };
  salary_amount: number;
  currency: string;
  salary_usd: number;
}

export type EmployeeDetail = Employee;

export interface PageMeta { page: number; per_page: number; total: number; total_pages: number }
export interface Page<T> { data: T[]; meta: PageMeta }

export interface EmployeeListQuery {
  q?: string;
  country?: string;
  department_id?: number | string | null;
  job_title_id?: number | string | null;
  sort?: string;
  direction?: 'asc' | 'desc';
  page?: number;
  per_page?: number;
}

export interface EmployeeInput {
  employee_code: string;
  name: string;
  email: string;
  country_code: string;
  department_id: number;
  job_title_id: number;
  salary_amount: number;
  currency: string;
}

export interface Metrics {
  employee_count: number;
  total_cost: number;
  average: number;
  median: number;
  lowest: number;
  highest: number;
}
export interface Summary extends Metrics { country_count: number; department_count: number }
export interface GroupRow extends Metrics {
  key: string | number;
  name: string;
  department?: string;
  currency?: string;
}
export interface DashboardData { summary: Summary; by_country: GroupRow[]; by_department: GroupRow[] }

export interface MatrixCell { country_code: string; department_id: number; employee_count: number; total_cost: number; average: number }
export interface DistributionBin { from: number; to: number | null; employee_count: number }
export interface Distribution {
  bin_width: number;
  bins: DistributionBin[];
  percentiles: { lowest: number; p25: number; median: number; p75: number; p90: number; highest: number };
}

export interface InsightFilters {
  country?: string;
  department_id?: number | string | null;
  job_title_id?: number | string | null;
}
export interface InsightResponse<T> { summary: Summary; data: T }
export type InsightReport = 'by_country' | 'by_department' | 'by_job_title' | 'matrix' | 'distribution';

export interface ApiErrorBody {
  error: { code: string; message: string; details?: Record<string, string[]> };
}

export interface User { id: number; email: string; name: string }
