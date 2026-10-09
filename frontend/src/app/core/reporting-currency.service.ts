import { Injectable, computed, inject, signal } from '@angular/core';
import { ApiService } from './api.service';
import { formatCompact, formatMoney } from './format';

const STORAGE_KEY = 'acme.reportingCurrency';

function readStored(): string {
  try {
    return localStorage.getItem(STORAGE_KEY) || 'USD';
  } catch {
    return 'USD'; // storage can be blocked; the choice just won't be remembered
  }
}

/**
 * The currency Dashboard and Insights amounts are shown in. The server reports
 * everything in USD at fixed rates; converting for display uses the same fixed
 * rates, so switching currency never changes the underlying numbers.
 */
@Injectable({ providedIn: 'root' })
export class ReportingCurrencyService {
  private readonly api = inject(ApiService);
  private readonly preferred = signal(readStored());
  private readonly rates = signal<Record<string, number>>({ USD: 1 });

  readonly options = computed(() => Object.keys(this.rates()).sort());
  /** Falls back to USD until rates load or if the saved choice no longer exists. */
  readonly code = computed(() => (this.rates()[this.preferred()] ? this.preferred() : 'USD'));
  readonly rate = computed(() => this.rates()[this.code()] ?? 1);

  constructor() {
    this.api.lookups().subscribe({
      next: (l) => this.rates.set(Object.fromEntries(l.currencies.map((c) => [c.code, c.rate_per_usd]))),
      error: () => { /* stay on USD; the page shows its own error */ },
    });
  }

  set(code: string): void {
    this.preferred.set(code);
    try {
      localStorage.setItem(STORAGE_KEY, code);
    } catch {
      /* ignore */
    }
  }

  /** Converts a USD amount into any supported currency at its fixed rate. */
  convertTo(usd: number, code: string): number {
    return usd * (this.rates()[code] ?? 1);
  }

  convert(usd: number): number {
    return usd * this.rate();
  }

  /** ₹18.4 L, $67.0k ... */
  compact(usd: number): string {
    return formatCompact(this.convert(usd), this.code());
  }

  /** ₹1,840,000 or $95,300 */
  full(usd: number): string {
    return formatMoney(this.convert(usd), this.code());
  }
}
