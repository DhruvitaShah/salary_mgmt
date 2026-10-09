import { HttpClient } from '@angular/common/http';
import { Injectable, inject, signal } from '@angular/core';
import { Observable, catchError, map, of, tap } from 'rxjs';
import { User } from './models';

/** Holds the signed-in HR user. The session itself is an HttpOnly cookie managed by the server. */
@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly http = inject(HttpClient);
  private readonly url = '/api/v1/session';

  readonly user = signal<User | null>(null);

  /** Asks the server whether the browser's session cookie is still valid. */
  check(): Observable<User | null> {
    return this.http.get<{ data: User }>(this.url).pipe(
      map((r) => r.data),
      catchError(() => of(null)),
      tap((u) => this.user.set(u)),
    );
  }

  login(email: string, password: string): Observable<User> {
    return this.http.post<{ data: User }>(this.url, { email, password }).pipe(
      map((r) => r.data),
      tap((u) => this.user.set(u)),
    );
  }

  logout(): Observable<unknown> {
    return this.http.delete(this.url).pipe(
      catchError(() => of(null)),
      tap(() => this.user.set(null)),
    );
  }

  /** Called when the server says the session ended (idle timeout, signed out elsewhere). */
  expire(): void {
    this.user.set(null);
  }
}
