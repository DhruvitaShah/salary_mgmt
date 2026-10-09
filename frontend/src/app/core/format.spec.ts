import { formatCompact, formatDate, formatMoney, formatUsdCompact } from './format';

describe('format helpers', () => {
  it('formats whole-number money in the given currency', () => {
    expect(formatMoney(95300, 'USD')).toBe('$95,300');
    expect(formatMoney(2660000, 'INR')).toContain('2,660,000');
  });

  it('formats compact USD for headline figures', () => {
    expect(formatUsdCompact(67012)).toBe('$67.0k');
    expect(formatUsdCompact(670_200_000)).toBe('$670.2M');
    expect(formatUsdCompact(2_300_000_000)).toBe('$2.30B');
  });

  it('formats compact amounts with a symbol that identifies the currency', () => {
    expect(formatCompact(95_300, 'EUR')).toBe('€95.3k');
    expect(formatCompact(95_300, 'CAD')).toBe('CA$95.3k');
    expect(formatCompact(12_000_000, 'JPY')).toBe('¥12.0M');
    expect(formatCompact(80_000, 'SGD')).toBe('SGD\u00A080.0k');
  });

  it('uses lakh and crore for INR', () => {
    expect(formatCompact(1_840_000, 'INR')).toBe('₹18.4 L');
    expect(formatCompact(18_400_000_000, 'INR')).toBe('₹1,840 Cr');
    expect(formatCompact(25_000_000, 'INR')).toBe('₹2.5 Cr');
    expect(formatCompact(45_000, 'INR')).toBe('₹45,000');
  });

  it('formats ISO dates without timezone drift', () => {
    expect(formatDate('2026-03-01')).toBe('1 Mar 2026');
    expect(formatDate('2025-12-31')).toBe('31 Dec 2025');
  });
});
