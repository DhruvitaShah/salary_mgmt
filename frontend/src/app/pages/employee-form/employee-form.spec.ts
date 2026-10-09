import { FormControl, FormGroup } from '@angular/forms';
import { plausibleSalary } from './employee-form.page';

describe('plausibleSalary validator', () => {
  const rates: Record<string, number> = { USD: 1, INR: 83.2 };
  const validator = plausibleSalary((c) => rates[c], 5_000, 2_000_000);
  const group = (amount: number | null, currency: string) =>
    new FormGroup({ salary_amount: new FormControl(amount), currency: new FormControl(currency) });

  it('accepts a normal salary', () => {
    expect(validator(group(95_000, 'USD'))).toBeNull();
  });

  it('judges local currencies by their USD equivalent', () => {
    expect(validator(group(4_160_000, 'INR'))).toBeNull(); // about $50k
    expect(validator(group(200_000, 'INR'))?.['implausible']).toBeTruthy(); // about $2.4k
  });

  it('flags absurdly high amounts', () => {
    expect(validator(group(9_000_000, 'USD'))?.['implausible']).toEqual({ usd: 9_000_000, min: 5_000, max: 2_000_000 });
  });

  it('stays quiet until there is something to judge', () => {
    expect(validator(group(null, 'USD'))).toBeNull();
    expect(validator(group(100, ''))).toBeNull();
  });
});
