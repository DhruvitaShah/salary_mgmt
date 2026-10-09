import { DecimalPipe } from '@angular/common';
import { Component, DestroyRef, OnInit, computed, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormsModule } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatPaginatorModule, PageEvent } from '@angular/material/paginator';
import { MatSelectModule } from '@angular/material/select';
import { MatSortModule, Sort } from '@angular/material/sort';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { Subject, debounceTime, distinctUntilChanged, switchMap, tap, catchError, of } from 'rxjs';
import { ApiService, friendlyError } from '../../core/api.service';
import { MoneyPipe } from '../../core/format';
import { Employee, EmployeeListQuery, Lookups, PageMeta } from '../../core/models';

@Component({
  selector: 'app-employee-list-page',
  imports: [
    DecimalPipe, FormsModule, RouterLink, MoneyPipe,
    MatButtonModule, MatFormFieldModule, MatInputModule, MatPaginatorModule, MatSelectModule, MatSortModule,
  ],
  templateUrl: './employee-list.page.html',
})
export class EmployeeListPage implements OnInit {
  private readonly api = inject(ApiService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);
  private readonly destroyRef = inject(DestroyRef);

  readonly lookups = signal<Lookups | null>(null);
  readonly rows = signal<Employee[]>([]);
  readonly meta = signal<PageMeta>({ page: 1, per_page: 25, total: 0, total_pages: 1 });
  readonly loading = signal(true);
  readonly error = signal('');

  readonly q = signal('');
  readonly country = signal('');
  readonly departmentId = signal<number | ''>('');
  readonly jobTitleId = signal<number | ''>('');
  readonly sort = signal<Sort>({ active: 'name', direction: 'asc' });
  readonly pageIndex = signal(0);
  readonly pageSize = signal(25);

  /** Job titles offered depend on the chosen department. */
  readonly titleOptions = computed(() => {
    const departments = this.lookups()?.departments ?? [];
    const dept = this.departmentId();
    const list = dept === '' ? departments.flatMap((d) => d.job_titles) : (departments.find((d) => d.id === dept)?.job_titles ?? []);
    return [...list].sort((a, b) => a.name.localeCompare(b.name));
  });

  private readonly load$ = new Subject<void>();
  private readonly search$ = new Subject<string>();

  ngOnInit(): void {
    const params = this.route.snapshot.queryParamMap;
    this.country.set(params.get('country') ?? '');
    this.departmentId.set(params.get('department_id') ? Number(params.get('department_id')) : '');

    this.api.lookups().pipe(takeUntilDestroyed(this.destroyRef)).subscribe({
      next: (l) => this.lookups.set(l),
      error: (e) => this.error.set(friendlyError(e).message),
    });

    this.search$.pipe(debounceTime(250), distinctUntilChanged(), takeUntilDestroyed(this.destroyRef)).subscribe((value) => {
      this.q.set(value);
      this.pageIndex.set(0);
      this.load$.next();
    });

    // switchMap cancels an in-flight request when a newer one starts, so slow
    // responses can never overwrite fresher results.
    this.load$.pipe(
      tap(() => { this.loading.set(true); this.error.set(''); }),
      switchMap(() => this.api.employees(this.query()).pipe(
        catchError((e) => { this.error.set(friendlyError(e).message); return of(null); }),
      )),
      takeUntilDestroyed(this.destroyRef),
    ).subscribe((page) => {
      this.loading.set(false);
      if (page) {
        this.rows.set(page.data);
        this.meta.set(page.meta);
      }
    });
    this.load$.next();
  }

  query(): EmployeeListQuery {
    const sort = this.sort();
    return {
      q: this.q(),
      country: this.country(),
      department_id: this.departmentId(),
      job_title_id: this.jobTitleId(),
      sort: sort.active,
      direction: sort.direction === 'desc' ? 'desc' : 'asc',
      page: this.pageIndex() + 1,
      per_page: this.pageSize(),
    };
  }

  onSearch(value: string) { this.search$.next(value); }

  onCountry(value: string) { this.country.set(value); this.resetPage(); }

  onDepartment(value: number | '') {
    this.departmentId.set(value);
    const stillValid = this.titleOptions().some((t) => t.id === this.jobTitleId());
    if (!stillValid) this.jobTitleId.set('');
    this.resetPage();
  }

  onTitle(value: number | '') { this.jobTitleId.set(value); this.resetPage(); }

  onSort(sort: Sort) {
    this.sort.set(sort.direction ? sort : { active: 'name', direction: 'asc' });
    this.resetPage();
  }

  onPage(event: PageEvent) {
    this.pageIndex.set(event.pageIndex);
    this.pageSize.set(event.pageSize);
    this.load$.next();
  }

  clear() {
    this.q.set('');
    this.country.set('');
    this.departmentId.set('');
    this.jobTitleId.set('');
    this.resetPage();
  }

  open(employee: Employee) { this.router.navigate(['/employees', employee.id]); }

  get hasFilters(): boolean {
    return !!(this.q() || this.country() || this.departmentId() !== '' || this.jobTitleId() !== '');
  }

  private resetPage() {
    this.pageIndex.set(0);
    this.load$.next();
  }
}
