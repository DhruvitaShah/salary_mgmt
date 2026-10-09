import { Component, inject } from '@angular/core';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatSelectModule } from '@angular/material/select';
import { ReportingCurrencyService } from '../core/reporting-currency.service';

@Component({
  selector: 'app-currency-picker',
  imports: [MatFormFieldModule, MatSelectModule],
  template: `
    <mat-form-field appearance="outline" subscriptSizing="dynamic" class="picker">
      <mat-label>Show amounts in</mat-label>
      <mat-select [value]="rc.code()" (selectionChange)="rc.set($event.value)">
        @for (c of rc.options(); track c) { <mat-option [value]="c">{{ c }}</mat-option> }
      </mat-select>
    </mat-form-field>
  `,
})
export class CurrencyPickerComponent {
  protected readonly rc = inject(ReportingCurrencyService);
}
