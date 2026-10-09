import { ApplicationConfig, inject, provideAppInitializer, provideZoneChangeDetection } from '@angular/core';
import { provideRouter, withComponentInputBinding } from '@angular/router';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { provideAnimationsAsync } from '@angular/platform-browser/animations/async';
import { firstValueFrom } from 'rxjs';
import { routes } from './app.routes';
import { AuthService } from './core/auth.service';
import { authInterceptor } from './core/auth.interceptor';

export const appConfig: ApplicationConfig = {
  providers: [
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes, withComponentInputBinding()),
    // Angular's built-in XSRF support copies the XSRF-TOKEN cookie into an
    // X-XSRF-TOKEN header on POST/PATCH/DELETE; the API checks it.
    provideHttpClient(withInterceptors([authInterceptor])),
    provideAnimationsAsync(),
    // Find out whether we are already signed in before the first route renders.
    provideAppInitializer(() => firstValueFrom(inject(AuthService).check())),
  ],
};
