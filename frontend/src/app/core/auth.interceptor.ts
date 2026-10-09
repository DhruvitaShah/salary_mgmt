import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, throwError } from 'rxjs';
import { AuthService } from './auth.service';

/**
 * If any API call comes back 401 while we think we are signed in, the session
 * has ended (for example after an hour idle). Return to the login page and
 * bring the user back to where they were after they sign in again.
 */
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const auth = inject(AuthService);
  const router = inject(Router);
  return next(req).pipe(
    catchError((err: unknown) => {
      const isSessionCall = req.url.endsWith('/session');
      if (err instanceof HttpErrorResponse && err.status === 401 && !isSessionCall && auth.user()) {
        auth.expire();
        router.navigate(['/login'], { queryParams: { returnUrl: router.url, expired: '1' } });
      }
      return throwError(() => err);
    }),
  );
};
