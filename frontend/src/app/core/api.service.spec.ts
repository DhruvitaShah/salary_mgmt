import { HttpErrorResponse } from '@angular/common/http';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { ApiService, friendlyError, toParams } from './api.service';

describe('toParams', () => {
  it('drops empty values and stringifies the rest', () => {
    const p = toParams({ q: '', country: 'US', page: 2, department_id: null, job_title_id: undefined });
    expect(p.keys()).toEqual(['country', 'page']);
    expect(p.get('page')).toBe('2');
  });
});

describe('friendlyError', () => {
  it('uses the API message and field details', () => {
    const err = new HttpErrorResponse({
      status: 422,
      error: { error: { code: 'validation_failed', message: 'Some fields need attention.', details: { email: ['is invalid'] } } },
    });
    expect(friendlyError(err)).toEqual({ message: 'Some fields need attention.', fields: { email: ['is invalid'] } });
  });

  it('explains network failures in plain language', () => {
    expect(friendlyError(new HttpErrorResponse({ status: 0 })).message).toContain('Cannot reach the server');
  });

  it('falls back to a generic message', () => {
    expect(friendlyError(new Error('boom')).message).toBe('Something went wrong. Please try again.');
  });
});

describe('ApiService', () => {
  let api: ApiService;
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({ providers: [provideHttpClient(), provideHttpClientTesting()] });
    api = TestBed.inject(ApiService);
    http = TestBed.inject(HttpTestingController);
  });
  afterEach(() => http.verify());

  it('sends list filters as query params', () => {
    api.employees({ q: 'ana', country: 'BR', sort: 'salary', direction: 'desc', page: 3, per_page: 50 }).subscribe();
    const req = http.expectOne((r) => r.url === '/api/v1/employees');
    expect(req.request.params.get('q')).toBe('ana');
    expect(req.request.params.get('direction')).toBe('desc');
    expect(req.request.params.get('page')).toBe('3');
    req.flush({ data: [], meta: { page: 3, per_page: 50, total: 0, total_pages: 1 } });
  });

  it('wraps the payload in an employee key', () => {
    api.updateEmployee(7, { name: 'New Name' }).subscribe();
    const req = http.expectOne('/api/v1/employees/7');
    expect(req.request.method).toBe('PATCH');
    expect(req.request.body).toEqual({ employee: { name: 'New Name' } });
    req.flush({ data: {} });
  });

  it('fetches lookups only once', () => {
    api.lookups().subscribe();
    api.lookups().subscribe();
    http.expectOne('/api/v1/lookups').flush({ countries: [], currencies: [], departments: [], salary_limits_usd: { min: 1, max: 2 } });
  });
});
