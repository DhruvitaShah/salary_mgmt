import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { ReportingCurrencyService } from './reporting-currency.service';

describe('ReportingCurrencyService', () => {
  let service: ReportingCurrencyService;

  beforeEach(() => {
    localStorage.clear();
    TestBed.configureTestingModule({ providers: [provideHttpClient(), provideHttpClientTesting()] });
    service = TestBed.inject(ReportingCurrencyService);
    TestBed.inject(HttpTestingController).expectOne('/api/v1/lookups').flush({
      countries: [], departments: [], salary_limits_usd: { min: 1, max: 2 },
      currencies: [{ code: 'USD', rate_per_usd: 1 }, { code: 'INR', rate_per_usd: 83.2 }],
    });
  });

  it('defaults to USD', () => {
    expect(service.code()).toBe('USD');
    expect(service.compact(67_000)).toBe('$67.0k');
  });

  it('converts at the fixed rate and formats lakh/crore for INR', () => {
    service.set('INR');
    expect(service.code()).toBe('INR');
    expect(service.convert(100)).toBeCloseTo(8320);
    expect(service.compact(22_115)).toBe('₹18.4 L');
  });

  it('converts to any currency without changing the saved choice', () => {
    expect(service.convertTo(100, 'INR')).toBeCloseTo(8320);
    expect(service.code()).toBe('USD');
  });

  it('remembers the choice', () => {
    service.set('INR');
    expect(localStorage.getItem('acme.reportingCurrency')).toBe('INR');
  });

  it('falls back to USD for a currency that no longer has a rate', () => {
    service.set('XXX');
    expect(service.code()).toBe('USD');
  });
});
