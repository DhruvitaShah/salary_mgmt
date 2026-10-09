import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { Distribution } from '../core/models';
import { ReportingCurrencyService } from '../core/reporting-currency.service';

interface BarGeometry { x: number; y: number; width: number; height: number; tip: string }
interface Tick { x?: number; y?: number; label: string }

/**
 * Salary distribution: employees per pay band, drawn to scale. Bands are $20k
 * wide on the server (USD equivalent); band edges and amounts are shown in the
 * currency chosen in the picker, so the bar shapes never change, only the labels.
 */
@Component({
  selector: 'app-histogram',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="chart">
      <svg viewBox="0 0 720 290" role="img" [attr.aria-label]="summary()">
        @for (t of yTicks(); track t.y) {
          <line [attr.x1]="left" [attr.x2]="720 - right" [attr.y1]="t.y" [attr.y2]="t.y" stroke="var(--line)" />
          <text [attr.x]="left - 8" [attr.y]="(t.y ?? 0) + 4" text-anchor="end">{{ t.label }}</text>
        }
        @for (b of bars(); track $index) {
          <rect [attr.x]="b.x" [attr.y]="b.y" [attr.width]="b.width" [attr.height]="b.height" rx="3" fill="var(--series)">
            <title>{{ b.tip }}</title>
          </rect>
        }
        <line [attr.x1]="left" [attr.x2]="720 - right" [attr.y1]="top + plotH" [attr.y2]="top + plotH" stroke="var(--ink-3)" />
        @for (t of xTicks(); track $index) {
          <text [attr.x]="t.x" [attr.y]="top + plotH + 16" text-anchor="middle">{{ t.label }}</text>
        }
        <text [attr.x]="left + plotW / 2" y="284" text-anchor="middle">Annual Salary ({{ rc.code() }}, bands of {{ bandWidth() }})</text>
        <text [attr.x]="left" y="12">Employees</text>
        <line [attr.x1]="medianX()" [attr.x2]="medianX()" [attr.y1]="top - 6" [attr.y2]="top + plotH"
              stroke="var(--ink)" stroke-width="2" stroke-dasharray="4 3" />
        <text [attr.x]="medianX() + (medianOnRight() ? -6 : 6)" [attr.y]="top + 4"
              [attr.text-anchor]="medianOnRight() ? 'end' : 'start'" style="fill: var(--ink); font-weight: 600">
          Median {{ medianLabel() }}
        </text>
      </svg>
    </div>
  `,
})
export class HistogramComponent {
  readonly distribution = input.required<Distribution>();
  readonly total = input.required<number>();
  protected readonly rc = inject(ReportingCurrencyService);
  readonly bandWidth = computed(() => this.rc.compact(this.distribution().bin_width));

  readonly left = 48;
  readonly right = 12;
  readonly top = 26;
  readonly plotW = 720 - 48 - 12;
  readonly plotH = 290 - 26 - 40;

  private readonly maxCount = computed(() => {
    const peak = Math.max(1, ...this.distribution().bins.map((b) => b.employee_count));
    const step = Math.pow(10, Math.floor(Math.log10(peak))) / 2;
    return Math.ceil((peak * 1.1) / step) * step;
  });

  readonly bars = computed<BarGeometry[]>(() => {
    const { bins, bin_width } = this.distribution();
    const bw = this.plotW / bins.length;
    const total = Math.max(this.total(), 1);
    return bins.map((b, i) => {
      const height = (b.employee_count / this.maxCount()) * this.plotH;
      const label = b.to === null
        ? `${this.rc.compact(b.from)} and above`
        : `${this.rc.compact(b.from)} – ${this.rc.compact(b.from + bin_width)}`;
      return {
        x: this.left + i * bw + 1,
        y: this.top + this.plotH - height,
        width: bw - 2,
        height,
        tip: `${label}: ${b.employee_count.toLocaleString('en-US')} employees (${((b.employee_count / total) * 100).toFixed(1)}%)`,
      };
    });
  });

  readonly yTicks = computed<Tick[]>(() =>
    [0, 1, 2, 3, 4].map((i) => {
      const value = (this.maxCount() * i) / 4;
      return { y: this.top + this.plotH - (value / this.maxCount()) * this.plotH, label: Math.round(value).toLocaleString('en-US') };
    }),
  );

  readonly xTicks = computed<Tick[]>(() => {
    const { bins, bin_width } = this.distribution();
    const bw = this.plotW / bins.length;
    return Array.from({ length: bins.length + 1 }, (_, i) => ({
      x: this.left + i * bw,
      label: i === 0 ? '0' : `${this.rc.compact(i * bin_width).replace(/^[^\d]+/, '')}${i === bins.length ? '+' : ''}`,
    }));
  });

  readonly medianX = computed(() => {
    const { bins, bin_width } = this.distribution();
    const domain = bins.length * bin_width;
    return this.left + (Math.min(this.distribution().percentiles.median, domain) / domain) * this.plotW;
  });
  readonly medianOnRight = computed(() => this.medianX() > this.left + this.plotW * 0.7);
  readonly medianLabel = computed(() => this.rc.compact(this.distribution().percentiles.median));
  readonly summary = computed(
    () => `Histogram of annual salaries in ${this.rc.code()}, bands of ${this.bandWidth()}. Median ${this.medianLabel()}.`,
  );
}
