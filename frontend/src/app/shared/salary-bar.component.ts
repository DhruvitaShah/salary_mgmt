import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';

/** A bar for the average with a tick for the median, both on one scale. */
@Component({
  selector: 'app-salary-bar',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="bar" role="img" [attr.aria-label]="label()" [title]="label()">
      <i [style.width.%]="averagePct()"></i>
      @if (median() !== null) { <b [style.left.%]="medianPct()"></b> }
    </div>
  `,
})
export class SalaryBarComponent {
  readonly average = input.required<number>();
  /** Omit for a plain bar (for example headcount). */
  readonly median = input<number | null>(null);
  readonly scale = input.required<number>();
  /** Text read by screen readers and shown on hover, already formatted by the page. */
  readonly label = input<string>('');

  readonly averagePct = computed(() => this.pct(this.average()));
  readonly medianPct = computed(() => this.pct(this.median() ?? 0));

  private pct(value: number): number {
    return this.scale() > 0 ? Math.min(100, (value / this.scale()) * 100) : 0;
  }
}
