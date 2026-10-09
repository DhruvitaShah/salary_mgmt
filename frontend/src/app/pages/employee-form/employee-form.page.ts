import { Component, DestroyRef, OnInit, computed, inject, input, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import {
  AbstractControl, FormBuilder, ReactiveFormsModule, ValidationErrors, ValidatorFn, Validators,
} from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { Router, RouterLink } from '@angular/router';
import { ApiService, friendlyError } from '../../core/api.service';
import { formatMoney } from '../../core/format';
import { EmployeeDetail, EmployeeInput, Lookups } from '../../core/models';

const CODE_PATTERN = /^[A-Za-z0-9][A-Za-z0-9-]{2,19}$/;
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

type FieldName = 'employee_code' | 'name' | 'email' | 'country_code' | 'department_id' | 'job_title_id' | 'salary_amount' | 'currency';

/** API error keys that differ from form control names. */
const SERVER_FIELD_MAP: Record<string, string> = { job_title: 'job_title_id', department: 'department_id' };

@Component({
  selector: 'app-employee-form-page',
  imports: [
    ReactiveFormsModule, RouterLink,
    MatButtonModule, MatFormFieldModule, MatInputModule, MatSelectModule, MatSnackBarModule,
  ],
  templateUrl: './employee-form.page.html',
})
export class EmployeeFormPage implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly api = inject(ApiService);
  private readonly router = inject(Router);
  private readonly snackBar = inject(MatSnackBar);
  private readonly destroyRef = inject(DestroyRef);

  /** Present when editing (route /employees/:id/edit). */
  readonly id = input<string>();

  readonly lookups = signal<Lookups | null>(null);
  readonly original = signal<EmployeeDetail | null>(null);
  readonly loading = signal(true);
  readonly saving = signal(false);
  readonly error = signal('');
  readonly isEdit = computed(() => !!this.id());

  readonly form = this.fb.nonNullable.group({
    employee_code: ['', [Validators.required, Validators.pattern(CODE_PATTERN)]],
    name: ['', [Validators.required, Validators.minLength(2), Validators.maxLength(80)]],
    email: ['', [Validators.required, Validators.pattern(EMAIL_PATTERN)]],
    country_code: ['', Validators.required],
    department_id: [0, [Validators.required, Validators.min(1)]],
    job_title_id: [0, [Validators.required, Validators.min(1)]],
    salary_amount: [null as number | null, [Validators.required, Validators.min(1)]],
    currency: ['', Validators.required],
  });

  private currencyTouched = false;
  private settingCurrency = false;

  /** Job titles for the chosen department. */
  readonly titles = signal<{ id: number; name: string }[]>([]);
  readonly usdHint = signal('Annual gross base salary in the employee’s local currency.');

  ngOnInit(): void {
    this.api.lookups().pipe(takeUntilDestroyed(this.destroyRef)).subscribe({
      next: (l) => {
        this.lookups.set(l);
        const id = this.id();
        if (id) this.loadEmployee(id);
        else this.loading.set(false);
      },
      error: (e) => { this.error.set(friendlyError(e).message); this.loading.set(false); },
    });
    this.wire();
  }

  private loadEmployee(id: string) {
    this.api.employee(id).pipe(takeUntilDestroyed(this.destroyRef)).subscribe({
      next: ({ data }) => {
        this.original.set(data);
        this.currencyTouched = true;
        this.setTitles(data.department.id);
        this.form.reset({
          employee_code: data.employee_code, name: data.name, email: data.email, country_code: data.country_code,
          department_id: data.department.id, job_title_id: data.job_title.id, salary_amount: data.salary_amount,
          currency: data.currency,
        });
        this.refreshSalaryHint();
        this.loading.set(false);
      },
      error: (e) => { this.error.set(friendlyError(e).message); this.loading.set(false); },
    });
  }

  private wire() {
    const f = this.form.controls;
    f.department_id.valueChanges.pipe(takeUntilDestroyed(this.destroyRef)).subscribe((id) => {
      this.setTitles(id);
      if (!this.titles().some((t) => t.id === f.job_title_id.value)) f.job_title_id.setValue(0);
    });
    f.country_code.valueChanges.pipe(takeUntilDestroyed(this.destroyRef)).subscribe((code) => {
      const country = this.lookups()?.countries.find((c) => c.code === code);
      if (country && !this.currencyTouched) {
        this.settingCurrency = true;
        f.currency.setValue(country.currency);
        this.settingCurrency = false;
      }
    });
    f.currency.valueChanges.pipe(takeUntilDestroyed(this.destroyRef)).subscribe(() => {
      if (!this.settingCurrency) this.currencyTouched = true;
    });
    this.form.valueChanges.pipe(takeUntilDestroyed(this.destroyRef)).subscribe(() => this.refreshSalaryHint());
  }

  private setTitles(departmentId: number) {
    this.titles.set(this.lookups()?.departments.find((d) => d.id === departmentId)?.job_titles ?? []);
  }

  private rate(currency: string): number | undefined {
    return this.lookups()?.currencies.find((c) => c.code === currency)?.rate_per_usd;
  }

  private refreshSalaryHint() {
    const f = this.form.controls;
    const amount = Number(f.salary_amount.value);
    const rate = this.rate(f.currency.value);
    this.usdHint.set(amount > 0 && rate
      ? `≈ ${formatMoney(amount / rate, 'USD')} at the fixed reporting rate`
      : 'Annual gross base salary in the employee’s local currency.');
  }

  /** Message for the first failing client-side rule of a control. */
  message(name: FieldName): string {
    const c = this.form.controls[name];
    if (!c.touched && !c.dirty) return '';
    const e = c.errors;
    if (!e) return '';
    if (e['server']) return e['server'] as string;
    if (e['required'] || e['min']) return 'This field is required.';
    if (e['minlength']) return 'Enter at least 2 characters.';
    if (e['maxlength']) return 'Keep this under 80 characters.';
    if (e['pattern']) return name === 'email' ? 'Enter a valid email address, like name@acme.com.' : 'Use 3–20 letters, numbers or dashes.';
    return 'This value is not valid.';
  }

  salaryMessage(): string {
    const c = this.form.controls.salary_amount;
    const own = this.message('salary_amount');
    if (own) return own;
    const implausible = this.form.errors?.['implausible'];
    if ((c.touched || c.dirty) && implausible) {
      return `That is about ${formatMoney(implausible.usd, 'USD')} a year in USD terms. Enter an amount between $5,000 and $2,000,000.`;
    }
    return '';
  }

  submit() {
    this.error.set('');
    this.form.markAllAsTouched();
    if (this.form.invalid) return;

    const v = this.form.getRawValue();
    const payload: EmployeeInput = {
      employee_code: v.employee_code.trim().toUpperCase(),
      name: v.name.trim(),
      email: v.email.trim().toLowerCase(),
      country_code: v.country_code,
      department_id: v.department_id,
      job_title_id: v.job_title_id,
      salary_amount: Number(v.salary_amount),
      currency: v.currency,
    };

    this.saving.set(true);
    const request = this.isEdit() ? this.api.updateEmployee(this.id()!, payload) : this.api.createEmployee(payload);
    request.pipe(takeUntilDestroyed(this.destroyRef)).subscribe({
      next: ({ data }) => {
        this.snackBar.open(this.isEdit() ? 'Changes saved' : `${data.name} added`, 'OK', { duration: 3500 });
        this.router.navigate(['/employees', data.id]);
      },
      error: (e) => {
        this.saving.set(false);
        const { message, fields } = friendlyError(e);
        this.error.set(message);
        for (const [field, messages] of Object.entries(fields)) {
          const control = this.form.get(SERVER_FIELD_MAP[field] ?? field);
          if (control) control.setErrors({ server: messages.join(' ') });
        }
      },
    });
  }
}
