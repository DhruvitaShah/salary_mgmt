import { Component, inject } from '@angular/core';
import { Router, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { AuthService } from './core/auth.service';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  template: `
    <div [class.app]="auth.user()">
      @if (auth.user(); as user) {
        <aside class="side">
          <div class="brand"><i>A</i> ACME Salary</div>
          <nav class="nav" aria-label="Main">
            <a routerLink="/dashboard" routerLinkActive="active" ariaCurrentWhenActive="page">Dashboard</a>
            <a routerLink="/employees" routerLinkActive="active" ariaCurrentWhenActive="page">Employees</a>
            <a routerLink="/insights" routerLinkActive="active" ariaCurrentWhenActive="page">Salary Insights</a>
          </nav>
          <div class="userbox">
            <div class="who"><b>{{ user.name }}</b><span>{{ user.email }}</span></div>
            <button type="button" class="signout" (click)="signOut()">Sign out</button>
          </div>
          <p class="note">Annual gross base salary, full-time employees. Cross-country figures use fixed exchange rates.</p>
        </aside>
      }
      <main id="main" tabindex="-1"><router-outlet /></main>
    </div>
  `,
})
export class AppComponent {
  protected readonly auth = inject(AuthService);
  private readonly router = inject(Router);

  signOut() {
    this.auth.logout().subscribe(() => this.router.navigate(['/login']));
  }
}
