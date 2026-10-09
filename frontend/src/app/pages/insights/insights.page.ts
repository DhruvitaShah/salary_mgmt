import { DecimalPipe } from '@angular/common';
import { Component, DestroyRef, OnInit, computed, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { MatButtonToggleModule } from '@angular/material/button-toggle';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatSelectModule } from '@angular/material/select';
import { Observable, Subject, catchError, map, of, switchMap, tap } from 'rxjs';
import { ApiService, friendlyError } from '../../core/api.service';
import { ReportingCurrencyService } from '../../core/reporting-currency.service';
import { Distribution, GroupRow, InsightFilters, Lookups, MatrixCell, Summary } from '../../core/models';
import { CurrencyPickerComponent } from '../../shared/currency-picker.component';
import { HistogramComponent } from '../../shared/histogram.component';
import { SalaryBarComponent } from '../../shared/salary-bar.component';

export type InsightTab = 'by_country' | 'by_department' | 'by_job_title' | 'matrix' | 'distribution';
export type MatrixMetric = 'cost' | 'count' | 'avg';

interface HeatCell { text: string; bg: string | null; tip: string }
interface HeatRow { name: string; cells: HeatCell[]; total: string }

@Component({
  selector: 'app-insights-page',
  imports: [
    DecimalPipe, SalaryBarComponent, HistogramComponent, CurrencyPickerComponent,
    MatButtonToggleModule, MatFormFieldModule, MatSelectModule,
  ],
  templateUrl: './insights.page.html',
})
export class InsightsPage implements OnInit {
  private readonly api = inject(ApiService);
  private readonly destroyRef = inject(DestroyRef);
  protected readonly rc = inject(ReportingCurrencyService);

  readonly tabs: { key: InsightTab; label: string }[] = [
    { key: 'by_country', label: 'By country' },
    { key: 'by_department', label: 'By department' },
    { key: 'by_job_title', label: 'By job title' },
    { key: 'matrix', label: 'Country × department' },
    { key: 'distribution', label: 'Distribution' },
  ];

  readonly lookups = signal<Lookups | null>(null);
  readonly country = signal('');
  readonly departmentId = signal<number | ''>('');
  readonly jobTitleId = signal<number | ''>('');
  readonly tab = signal<InsightTab>('by_country');
  readonly metric = signal<MatrixMetric>('cost');

  readonly summary = signal<Summary | null>(null);
  readonly groups = signal<GroupRow[]>([]);
  readonly cells = signal<MatrixCell[]>([]);
  readonly distribution = signal<Distribution | null>(null);
  readonly loading = signal(true);
  readonly error = signal('');

  private readonly reload$ = new Subject<void>();

  /** Job titles offered depend on the chosen department. */
  readonly titleOptions = computed(() => {
    const departments = this.lookups()?.departments ?? [];
    const dept = this.departmentId();
    const list = dept === '' ? departments.flatMap((d) => d.job_titles) : (departments.find((d) => d.id === dept)?.job_titles ?? []);
    return [...list].sort((a, b) => a.name.localeCompare(b.name));
  });

  readonly groupLabel = computed(() => ({ by_country: 'Country', by_department: 'Department', by_job_title: 'Job Title', matrix: '', distribution: '' }[this.tab()]));
  readonly scale = computed(() => Math.max(0, ...this.groups().map((g) => Math.max(g.average, g.median))) * 1.08);

  readonly matrixTitle = computed(() => ({ cost: 'Total annual salary cost', count: 'Employee count', avg: 'Average salary' }[this.metric()]));

  readonly heat = computed(() => {
    const l = this.lookups();
    const cells = this.cells();
    if (!l || cells.length === 0) return null;
    const metric = this.metric();
    const depts = l.departments.filter((d) => cells.some((c) => c.department_id === d.id));
    const countries = l.countries.filter((c) => cells.some((x) => x.country_code === c.code));

    const value = (count: number, total: number): number | null =>
      count === 0 ? null : metric === 'cost' ? total : metric === 'count' ? count : total / count;
    const text = (v: number | null) => (v === null ? '–' : metric === 'count' ? v.toLocaleString('en-US') : this.rc.compact(v));
    const tip = (label: string, v: number) =>
      metric === 'count' ? `${label}: ${v.toLocaleString('en-US')} employees`
        : `${label}: ${this.rc.full(v)} ${metric === 'cost' ? 'total annual cost' : 'average'}`;

    const byKey = new Map(cells.map((c) => [`${c.country_code}|${c.department_id}`, c]));
    let max = 0;
    for (const c of cells) max = Math.max(max, value(c.employee_count, c.total_cost) ?? 0);

    const rowTotals = (code: string) => cells.filter((c) => c.country_code === code)
      .reduce((a, c) => ({ n: a.n + c.employee_count, t: a.t + c.total_cost }), { n: 0, t: 0 });
    const colTotals = (id: number) => cells.filter((c) => c.department_id === id)
      .reduce((a, c) => ({ n: a.n + c.employee_count, t: a.t + c.total_cost }), { n: 0, t: 0 });
    const grand = cells.reduce((a, c) => ({ n: a.n + c.employee_count, t: a.t + c.total_cost }), { n: 0, t: 0 });

    const rows: HeatRow[] = countries
      .map((c) => ({ c, totals: rowTotals(c.code) }))
      .sort((a, b) => b.totals.t - a.totals.t)
      .map(({ c, totals }) => ({
        name: c.name,
        total: text(value(totals.n, totals.t)),
        cells: depts.map((d) => {
          const cell = byKey.get(`${c.code}|${d.id}`);
          const v = cell ? value(cell.employee_count, cell.total_cost) : null;
          return {
            text: text(v),
            bg: v === null || max === 0 ? null : `color-mix(in srgb, var(--series) ${Math.round(6 + (v / max) * 48)}%, var(--surface))`,
            tip: v === null ? '' : tip(`${c.name} · ${d.name}`, v),
          };
        }),
      }));

    return {
      departments: depts.map((d) => d.name),
      rows,
      footer: depts.map((d) => { const t = colTotals(d.id); return text(value(t.n, t.t)); }),
      grand: text(value(grand.n, grand.t)),
    };
  });

  ngOnInit(): void {
    this.api.lookups().pipe(takeUntilDestroyed(this.destroyRef)).subscribe({
      next: (l) => this.lookups.set(l),
      error: (e) => this.error.set(friendlyError(e).message),
    });

    // Only the active view is fetched; switchMap drops stale responses.
    this.reload$.pipe(
      tap(() => { this.loading.set(true); this.error.set(''); }),
      switchMap(() => this.fetch().pipe(
        catchError((e) => { this.error.set(friendlyError(e).message); return of(null); }),
      )),
      takeUntilDestroyed(this.destroyRef),
    ).subscribe(() => this.loading.set(false));
    this.reload$.next();
  }

  private filters(): InsightFilters {
    return { country: this.country(), department_id: this.departmentId(), job_title_id: this.jobTitleId() };
  }

  private fetch(): Observable<unknown> {
    const f = this.filters();
    const tab = this.tab();
    const keepSummary = (s: Summary) => this.summary.set(s);
    switch (tab) {
      case 'matrix':
        return this.api.matrix(f).pipe(tap((r) => { keepSummary(r.summary); this.cells.set(r.data); }), map(() => true));
      case 'distribution':
        return this.api.distribution(f).pipe(tap((r) => { keepSummary(r.summary); this.distribution.set(r.data); }), map(() => true));
      default:
        return this.api.groupReport(tab, f).pipe(tap((r) => { keepSummary(r.summary); this.groups.set(r.data); }), map(() => true));
    }
  }

  setTab(tab: InsightTab) {
    this.tab.set(tab);
    this.groups.set([]);
    this.reload$.next();
  }
  setMetric(metric: MatrixMetric) { this.metric.set(metric); }
  setCountry(code: string) { this.country.set(code); this.reload$.next(); }
  setDepartment(id: number | '') {
    this.departmentId.set(id);
    if (!this.titleOptions().some((t) => t.id === this.jobTitleId())) this.jobTitleId.set('');
    this.reload$.next();
  }
  setJobTitle(id: number | '') { this.jobTitleId.set(id); this.reload$.next(); }

  barLabel(row: GroupRow): string {
    return `${row.name}: average ${this.rc.full(row.average)}, median ${this.rc.full(row.median)}`;
  }

  departmentOf(row: GroupRow): string { return row.department ?? ''; }
  currencyOf(row: GroupRow): string { return row.currency ?? ''; }
}
