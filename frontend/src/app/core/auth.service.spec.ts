import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { AuthService } from './auth.service';
import { safeReturnUrl } from '../pages/login/login.page';

describe('AuthService', () => {
  let auth: AuthService;
  let http: HttpTestingController;
  const hr = { id: 1, email: 'hr@acme.com', name: 'HR Manager' };

  beforeEach(() => {
    TestBed.configureTestingModule({ providers: [provideHttpClient(), provideHttpClientTesting()] });
    auth = TestBed.inject(AuthService);
    http = TestBed.inject(HttpTestingController);
  });
  afterEach(() => http.verify());

  it('is signed out until the server says otherwise', () => {
    expect(auth.user()).toBeNull();
  });

  it('check() stores the user when the session cookie is valid', () => {
    auth.check().subscribe();
    http.expectOne('/api/v1/session').flush({ data: hr });
    expect(auth.user()).toEqual(hr);
  });

  it('check() treats a 401 as signed out instead of failing', () => {
    auth.check().subscribe();
    http.expectOne('/api/v1/session').flush({ error: { code: 'unauthorized', message: 'x' } }, { status: 401, statusText: 'Unauthorized' });
    expect(auth.user()).toBeNull();
  });

  it('login() posts the credentials and stores the user', () => {
    auth.login('hr@acme.com', 'secret-password-1').subscribe();
    const req = http.expectOne('/api/v1/session');
    expect(req.request.method).toBe('POST');
    expect(req.request.body).toEqual({ email: 'hr@acme.com', password: 'secret-password-1' });
    req.flush({ data: hr });
    expect(auth.user()).toEqual(hr);
  });

  it('logout() clears the user even if the request fails', () => {
    auth.user.set(hr);
    auth.logout().subscribe();
    http.expectOne('/api/v1/session').error(new ProgressEvent('error'));
    expect(auth.user()).toBeNull();
  });
});

describe('safeReturnUrl', () => {
  it('allows in-app paths', () => {
    expect(safeReturnUrl('/employees/42')).toBe('/employees/42');
    expect(safeReturnUrl('/employees?country=US')).toBe('/employees?country=US');
  });

  it('refuses anything that could leave the app', () => {
    expect(safeReturnUrl('https://evil.example')).toBe('/dashboard');
    expect(safeReturnUrl('//evil.example')).toBe('/dashboard');
    expect(safeReturnUrl('/\\evil.example')).toBe('/dashboard');
    expect(safeReturnUrl('javascript:alert(1)')).toBe('/dashboard');
  });

  it('falls back to the dashboard for empty values and the login page itself', () => {
    expect(safeReturnUrl(null)).toBe('/dashboard');
    expect(safeReturnUrl('')).toBe('/dashboard');
    expect(safeReturnUrl('/login?expired=1')).toBe('/dashboard');
  });
});
