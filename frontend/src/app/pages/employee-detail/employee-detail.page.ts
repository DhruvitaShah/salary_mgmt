import { Component, DestroyRef, computed, inject, input, signal } from '@angular/core';
import { takeUntilDestroyed, toObservable } from '@angular/core/rxjs-interop';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatSelectModule } from '@angular/material/select';
import { RouterLink } from '@angular/router';
import { catchError, of, switchMap, tap } from 'rxjs';
import { ApiService, friendlyError } from '../../core/api.service';
import { MoneyPipe, formatMoney } from '../../core/format';
import { ReportingCurrencyService } from '../../core/reporting-currency.service';
import { EmployeeDetail } from '../../core/models';

@Component({
  selector: 'app-employee-detail-page',
  imports: [RouterLink, MatButtonModule, MatFormFieldModule, MatSelectModule, MoneyPipe],
  templateUrl: './employee-detail.page.html',
})
export class EmployeeDetailPage {
  private readonly api = inject(ApiService);
  protected readonly rc = inject(ReportingCurrencyService);

  /** Bound from the :id route parameter (withComponentInputBinding). */
  readonly id = input.required<string>();

  readonly employee = signal<EmployeeDetail | null>(null);
  readonly error = signal('');

  /** '' = the employee's own (local) currency; otherwise a currency code to convert to. */
  readonly view = signal('');
  readonly shownCurrency = computed(() => this.view() || this.employee()?.currency || 'USD');
  readonly shownAmount = computed(() => {
    const e = this.employee();
    if (!e) return '';
    const code = this.shownCurrency();
    return code === e.currency ? formatMoney(e.salary_amount, code) : formatMoney(this.rc.convertTo(e.salary_usd, code), code);
  });
  readonly converted = computed(() => { const e = this.employee(); return !!e && this.shownCurrency() !== e.currency; });

  constructor() {
    toObservable(this.id).pipe(
      tap(() => { this.employee.set(null); this.error.set(''); }),
      switchMap((id) => this.api.employee(id).pipe(
        catchError((e) => { this.error.set(friendlyError(e).message); return of(null); }),
      )),
      takeUntilDestroyed(inject(DestroyRef)),
    ).subscribe((r) => { if (r) this.employee.set(r.data); });
  }
}
