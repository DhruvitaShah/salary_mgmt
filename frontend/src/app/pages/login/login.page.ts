import { Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { ActivatedRoute, Router } from '@angular/router';
import { friendlyError } from '../../core/api.service';
import { AuthService } from '../../core/auth.service';

/** Only follow in-app paths after login, so a crafted link cannot send HR to another site. */
export function safeReturnUrl(url: string | null | undefined): string {
  const ok = !!url && url.startsWith('/') && !url.startsWith('//') && !url.startsWith('/\\') && !url.startsWith('/login');
  return ok ? url : '/dashboard';
}

@Component({
  selector: 'app-login-page',
  imports: [ReactiveFormsModule, MatButtonModule, MatFormFieldModule, MatInputModule],
  template: `
    <section class="panel login" aria-labelledby="login-title">
      <div class="bd">
        <div class="brand"><i>A</i> Salary Management</div>
        <h1 id="login-title">Sign in</h1>
        <p class="sub">Use the HR account to manage employees and salaries.</p>

        @if (expired) { <div class="banner" role="status">Your session ended. Please sign in again.</div> }
        @if (error()) { <div class="banner" role="alert">{{ error() }}</div> }

        <form [formGroup]="form" (ngSubmit)="submit()" novalidate>
          <mat-form-field appearance="outline">
            <mat-label>Email</mat-label>
            <input matInput type="email" formControlName="email" autocomplete="username" autofocus />
            @if (form.controls.email.touched && form.controls.email.invalid) {
              <mat-error>Enter your email address.</mat-error>
            }
          </mat-form-field>

          <mat-form-field appearance="outline">
            <mat-label>Password</mat-label>
            <input matInput [type]="showPassword() ? 'text' : 'password'" formControlName="password" autocomplete="current-password" />
            <button mat-button matSuffix type="button" (click)="showPassword.set(!showPassword())"
                    [attr.aria-pressed]="showPassword()">{{ showPassword() ? 'Hide' : 'Show' }}</button>
            @if (form.controls.password.touched && form.controls.password.invalid) {
              <mat-error>Enter your password.</mat-error>
            }
          </mat-form-field>

          <button mat-flat-button type="submit" class="full" [disabled]="busy()">
            {{ busy() ? 'Signing in…' : 'Sign in' }}
          </button>
        </form>
      </div>
    </section>
  `,
})
export class LoginPage {
  private readonly fb = inject(FormBuilder);
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);

  readonly expired = this.route.snapshot.queryParamMap.get('expired') === '1';
  private readonly returnUrl = this.route.snapshot.queryParamMap.get('returnUrl');

  readonly form = this.fb.nonNullable.group({
    email: ['', [Validators.required]],
    password: ['', [Validators.required]],
  });
  readonly busy = signal(false);
  readonly error = signal('');
  readonly showPassword = signal(false);

  constructor() {
    if (this.auth.user()) this.router.navigateByUrl(safeReturnUrl(this.returnUrl));
  }

  submit() {
    this.error.set('');
    this.form.markAllAsTouched();
    if (this.form.invalid) return;

    const { email, password } = this.form.getRawValue();
    this.busy.set(true);
    this.auth.login(email.trim(), password).subscribe({
      next: () => this.router.navigateByUrl(safeReturnUrl(this.returnUrl)),
      error: (e) => {
        this.busy.set(false);
        this.form.controls.password.reset('');
        this.error.set(friendlyError(e).message);
      },
    });
  }
}
