import { HttpClient, HttpErrorResponse, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, shareReplay } from 'rxjs';
import {
  ApiErrorBody, DashboardData, Distribution, EmployeeDetail, EmployeeInput, EmployeeListQuery, Employee,
  GroupRow, InsightFilters, InsightReport, InsightResponse, Lookups, MatrixCell, Page,
} from './models';

/** Builds query params, dropping empty values so URLs stay clean. */
export function toParams(values: object): HttpParams {
  let params = new HttpParams();
  for (const [key, value] of Object.entries(values)) {
    if (value !== null && value !== undefined && value !== '') {
      params = params.set(key, String(value));
    }
  }
  return params;
}

export interface FriendlyError {
  message: string;
  /** Field name to messages, as returned by the API for 422 responses. */
  fields: Record<string, string[]>;
}

/** Converts any HTTP failure into something a non-technical user can read. */
export function friendlyError(err: unknown): FriendlyError {
  if (err instanceof HttpErrorResponse) {
    if (err.status === 0) {
      return { message: 'Cannot reach the server. Check your connection and try again.', fields: {} };
    }
    const body = err.error as Partial<ApiErrorBody> | null;
    if (body?.error) {
      return { message: body.error.message, fields: body.error.details ?? {} };
    }
  }
  return { message: 'Something went wrong. Please try again.', fields: {} };
}

@Injectable({ providedIn: 'root' })
export class ApiService {
  private readonly http = inject(HttpClient);
  private readonly base = '/api/v1';
  private lookups$?: Observable<Lookups>;

  /** Reference data never changes during a session, so fetch it once. */
  lookups(): Observable<Lookups> {
    this.lookups$ ??= this.http.get<Lookups>(`${this.base}/lookups`).pipe(shareReplay(1));
    return this.lookups$;
  }

  employees(query: EmployeeListQuery): Observable<Page<Employee>> {
    return this.http.get<Page<Employee>>(`${this.base}/employees`, { params: toParams(query) });
  }

  employee(id: number | string): Observable<{ data: EmployeeDetail }> {
    return this.http.get<{ data: EmployeeDetail }>(`${this.base}/employees/${id}`);
  }

  createEmployee(input: EmployeeInput): Observable<{ data: EmployeeDetail }> {
    return this.http.post<{ data: EmployeeDetail }>(`${this.base}/employees`, { employee: input });
  }

  updateEmployee(id: number | string, input: Partial<EmployeeInput>): Observable<{ data: EmployeeDetail }> {
    return this.http.patch<{ data: EmployeeDetail }>(`${this.base}/employees/${id}`, { employee: input });
  }

  dashboard(): Observable<DashboardData> {
    return this.http.get<DashboardData>(`${this.base}/dashboard`);
  }

  groupReport(report: 'by_country' | 'by_department' | 'by_job_title', filters: InsightFilters) {
    return this.insight<GroupRow[]>(report, filters);
  }

  matrix(filters: InsightFilters) {
    return this.insight<MatrixCell[]>('matrix', filters);
  }

  distribution(filters: InsightFilters) {
    return this.insight<Distribution>('distribution', filters);
  }

  private insight<T>(report: InsightReport, filters: InsightFilters): Observable<InsightResponse<T>> {
    return this.http.get<InsightResponse<T>>(`${this.base}/insights/${report}`, { params: toParams(filters) });
  }
}
