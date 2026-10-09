import { DecimalPipe } from '@angular/common';
import { Component, DestroyRef, computed, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { Router } from '@angular/router';
import { ApiService, friendlyError } from '../../core/api.service';
import { ReportingCurrencyService } from '../../core/reporting-currency.service';
import { DashboardData, GroupRow } from '../../core/models';
import { CurrencyPickerComponent } from '../../shared/currency-picker.component';
import { SalaryBarComponent } from '../../shared/salary-bar.component';

@Component({
  selector: 'app-dashboard-page',
  imports: [DecimalPipe, SalaryBarComponent, CurrencyPickerComponent],
  templateUrl: './dashboard.page.html',
})
export class DashboardPage {
  private readonly api = inject(ApiService);
  private readonly router = inject(Router);
  protected readonly rc = inject(ReportingCurrencyService);

  readonly data = signal<DashboardData | null>(null);
  readonly error = signal('');

  /** One shared scale so country and department salary bars are comparable. */
  readonly salaryScale = computed(() => {
    const d = this.data();
    if (!d) return 0;
    return Math.max(...[...d.by_country, ...d.by_department].map((r) => Math.max(r.average, r.median))) * 1.08;
  });

  readonly countByCountry = computed(() => this.byCount(this.data()?.by_country ?? []));
  readonly countByDepartment = computed(() => this.byCount(this.data()?.by_department ?? []));
  readonly countScale = computed(() => {
    const d = this.data();
    if (!d) return 0;
    return Math.max(...[...d.by_country, ...d.by_department].map((r) => r.employee_count)) * 1.08;
  });

  constructor() {
    this.api.dashboard().pipe(takeUntilDestroyed(inject(DestroyRef))).subscribe({
      next: (d) => this.data.set(d),
      error: (e) => this.error.set(friendlyError(e).message),
    });
  }

  salaryLabel(row: GroupRow): string {
    return `${row.name}: average ${this.rc.full(row.average)}, median ${this.rc.full(row.median)}`;
  }

  openCountry(row: GroupRow) {
    this.router.navigate(['/employees'], { queryParams: { country: row.key } });
  }

  openDepartment(row: GroupRow) {
    this.router.navigate(['/employees'], { queryParams: { department_id: row.key } });
  }

  private byCount(rows: GroupRow[]): GroupRow[] {
    return [...rows].sort((a, b) => b.employee_count - a.employee_count);
  }
}
