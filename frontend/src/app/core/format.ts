import { Pipe, PipeTransform } from '@angular/core';

const formatters = new Map<string, Intl.NumberFormat>();

/** Whole-number currency, e.g. "$95,300" or "₹2,660,000". */
export function formatMoney(value: number, currency: string): string {
  let f = formatters.get(currency);
  if (!f) {
    f = new Intl.NumberFormat('en-US', { style: 'currency', currency, maximumFractionDigits: 0 });
    formatters.set(currency, f);
  }
  return f.format(value);
}

const symbols = new Map<string, string>();

/** Currency symbol that tells similar currencies apart: $, CA$, A$, €, £, ¥, ₹, R$. */
export function currencySymbol(currency: string): string {
  let symbol = symbols.get(currency);
  if (symbol === undefined) {
    const parts = new Intl.NumberFormat('en-US', { style: 'currency', currency }).formatToParts(0);
    symbol = parts.find((p) => p.type === 'currency')?.value ?? currency;
    symbols.set(currency, symbol);
  }
  return symbol;
}

/**
 * Short form for headline figures: $67.0k, $670.2M, €1.2M.
 * INR uses the Indian system the way HR in India reads it: ₹18.4 L (lakh), ₹1,840 Cr (crore).
 */
export function formatCompact(value: number, currency: string): string {
  const symbol = currencySymbol(currency);
  const prefix = /^[A-Za-z]+$/.test(symbol) ? `${symbol}\u00A0` : symbol; // "SGD 67.0k" needs a space
  if (currency === 'INR') {
    if (value >= 1e7) {
      const crore = value / 1e7;
      return `${prefix}${crore.toLocaleString('en-IN', { maximumFractionDigits: crore >= 100 ? 0 : 1 })} Cr`;
    }
    if (value >= 1e5) return `${prefix}${(value / 1e5).toFixed(1)} L`;
    return `${prefix}${Math.round(value).toLocaleString('en-IN')}`;
  }
  if (value >= 1e9) return `${prefix}${(value / 1e9).toFixed(2)}B`;
  if (value >= 1e6) return `${prefix}${(value / 1e6).toFixed(1)}M`;
  return `${prefix}${(value / 1e3).toFixed(1)}k`;
}

/** Compact USD for headline figures: $67.0k, $670.2M. */
export function formatUsdCompact(value: number): string {
  return formatCompact(value, 'USD');
}

export function formatDate(iso: string): string {
  const [y, m, d] = iso.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d)).toLocaleDateString('en-GB', {
    day: 'numeric', month: 'short', year: 'numeric', timeZone: 'UTC',
  });
}

@Pipe({ name: 'money' })
export class MoneyPipe implements PipeTransform {
  transform(value: number | null | undefined, currency: string): string {
    return value === null || value === undefined ? '' : formatMoney(value, currency);
  }
}
