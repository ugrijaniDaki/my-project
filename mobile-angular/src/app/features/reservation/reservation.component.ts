import { Component, OnInit, inject, ChangeDetectorRef, NgZone } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatDialogModule, MatDialog } from '@angular/material/dialog';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { ApiService } from '../../core/services/api.service';
import { AuthService } from '../../core/services/auth.service';
import { I18nService } from '../../core/services/i18n.service';
import { ScheduleResponse, TimeSlot, ReservationRequest } from '../../core/models/reservation.model';
import { AuthDialogComponent } from '../../shared/components/auth-modal/auth-dialog.component';

interface CalendarDay {
  date: Date;
  day: number;
  dateStr: string;
  status: 'available' | 'limited' | 'full' | 'closed' | 'past' | 'disabled';
  isToday: boolean;
  isSelected: boolean;
}

@Component({
  selector: 'app-reservation',
  standalone: true,
  imports: [
    CommonModule, FormsModule, MatButtonModule, MatIconModule,
    MatDialogModule, MatSnackBarModule
  ],
  template: `
    <div class="reservation-page">
      @if (!success) {
        <!-- Header -->
        <header class="res-header">
          <h1>Aura</h1>
          <div class="divider"></div>
          <p class="season">Sezona 2026.</p>
        </header>

        <!-- User Bar -->
        @if (authService.currentUser) {
          <div class="user-bar">
            <div class="user-info">
              <div class="user-avatar">{{ authService.currentUser.name.charAt(0) }}</div>
              <span>{{ authService.currentUser.name }}</span>
            </div>
            <button class="logout-btn" (click)="logout()">
              <mat-icon>logout</mat-icon>
            </button>
          </div>
        }

        <!-- Calendar -->
        <section class="calendar-section">
          <label>Odaberite datum</label>

          <div class="calendar-nav">
            <button (click)="prevMonth()" [disabled]="!canGoPrev" class="nav-btn">
              <mat-icon>chevron_left</mat-icon>
            </button>
            <span class="month-label">{{ monthNames[currentMonth] }} {{ currentYear }}</span>
            <button (click)="nextMonth()" [disabled]="!canGoNext" class="nav-btn">
              <mat-icon>chevron_right</mat-icon>
            </button>
          </div>

          <div class="calendar-grid">
            <div class="weekday-header">
              @for (day of weekdays; track day) {
                <span>{{ day }}</span>
              }
            </div>
            <div class="days-grid">
              @for (day of calendarDays; track day.dateStr) {
                <button class="cal-day"
                        [class.available]="day.status === 'available'"
                        [class.limited]="day.status === 'limited'"
                        [class.full]="day.status === 'full'"
                        [class.closed]="day.status === 'closed'"
                        [class.past]="day.status === 'past'"
                        [class.disabled]="day.status === 'disabled'"
                        [class.today]="day.isToday"
                        [class.selected]="day.isSelected"
                        [disabled]="day.status === 'disabled' || day.status === 'past' || day.status === 'closed' || day.status === 'full'"
                        (click)="selectDate(day)">
                  {{ day.day || '' }}
                </button>
              }
            </div>
          </div>

          <!-- Legend -->
          <div class="legend">
            <div class="legend-item"><span class="dot available"></span>Dostupno</div>
            <div class="legend-item"><span class="dot limited"></span>Ograničeno</div>
            <div class="legend-item"><span class="dot full"></span>Popunjeno</div>
            <div class="legend-item"><span class="dot closed"></span>Zatvoreno</div>
          </div>

          <!-- Selected Date Display -->
          @if (selectedDate) {
            <div class="selected-date-display">
              {{ formatSelectedDate() }}
            </div>
          }
        </section>

        <!-- Time Slots -->
        <section class="slots-section">
          <label>Dostupni termini</label>

          @if (loadingSlots) {
            <div class="loading-slots">
              <mat-icon class="spin">sync</mat-icon>
              <p>Učitavam termine...</p>
              <p class="loading-hint">Molimo pričekajte...</p>
            </div>
          }

          @if (slotsError && !loadingSlots) {
            <div class="error-slots">
              <mat-icon>cloud_off</mat-icon>
              <p>Greška pri učitavanju</p>
              <button class="retry-btn" (click)="loadSlots(selectedDate!)">
                <mat-icon>refresh</mat-icon>
                Pokušaj ponovo
              </button>
            </div>
          }

          @if (isClosed && !loadingSlots) {
            <div class="closed-message">
              <p class="closed-title">Zatvoreno</p>
              <p class="closed-reason">{{ closedReason || 'Restoran ne radi ovaj dan' }}</p>
            </div>
          }

          @if (!loadingSlots && !isClosed && slots.length > 0) {
            <div class="slots-grid">
              @for (slot of slots; track slot.time) {
                <button class="slot-btn"
                        [class.available]="slot.available > 0"
                        [class.full]="slot.available <= 0"
                        [class.selected]="selectedSlot === slot.time"
                        [disabled]="slot.available <= 0"
                        (click)="selectSlot(slot.time)">
                  <span class="slot-time">{{ slot.time }}</span>
                  <span class="slot-status">{{ slot.available > 0 ? 'Slobodno' : 'Popunjeno' }}</span>
                </button>
              }
            </div>
          }
        </section>

        <!-- Guest Count -->
        <section class="guests-section">
          <label>Broj gostiju</label>
          <div class="guest-counter">
            <button class="counter-btn" (click)="updateGuests(-1)" [disabled]="guests <= 1">−</button>
            <span class="guest-count">{{ guests }}</span>
            <button class="counter-btn" (click)="updateGuests(1)" [disabled]="guests >= 8">+</button>
          </div>
        </section>

        <!-- Notes -->
        <section class="notes-section">
          <label>Posebni zahtjevi (opcionalno)</label>
          <textarea [(ngModel)]="notes" placeholder="Alergije, posebne prigode..."></textarea>
        </section>

        <!-- Price -->
        <section class="price-section">
          <div class="price-row">
            <div>
              <p class="price-label">Cijena po osobi</p>
              <p class="price-value">95,00 €</p>
            </div>
            <div class="price-total">
              <p class="price-label">Ukupno</p>
              <p class="total-value">{{ (guests * 95).toFixed(2).replace('.', ',') }} €</p>
            </div>
          </div>
        </section>

        <!-- Submit -->
        <button class="submit-btn"
                [disabled]="!canSubmit || loading"
                (click)="submitReservation()">
          {{ loading ? 'Šaljem...' : (canSubmit ? 'Potvrdi rezervaciju' : 'Odaberite termin') }}
        </button>
      }

      @if (success) {
        <!-- Success Screen -->
        <div class="success-screen">
          <div class="success-divider"></div>
          <h2>Uspješno</h2>
          <div class="success-summary" [innerHTML]="successMessage"></div>
          <button class="back-btn" routerLink="/home">Natrag na početnu</button>
        </div>
      }
    </div>
  `,
  styles: [`
    .reservation-page {
      background: white;
      min-height: 100vh;
      padding: 32px 24px 120px;
      border-radius: 32px;
      margin: 16px;
      box-shadow: 0 20px 40px rgba(0, 0, 0, 0.05);
    }

    .res-header {
      text-align: center;
      margin-bottom: 24px;

      h1 {
        font-size: 28px;
        font-weight: 300;
        letter-spacing: 0.4em;
        text-transform: uppercase;
        color: #1C1917;
      }

      .divider {
        width: 40px;
        height: 1px;
        background: #d6d3d1;
        margin: 16px auto;
      }

      .season {
        font-size: 10px;
        text-transform: uppercase;
        letter-spacing: 0.2em;
        color: #a8a29e;
        font-style: italic;
      }
    }

    .user-bar {
      display: flex;
      justify-content: space-between;
      align-items: center;
      background: #fafaf9;
      padding: 8px 12px 8px 16px;
      border-radius: 50px;
      margin-bottom: 24px;
    }

    .user-info {
      display: flex;
      align-items: center;
      gap: 10px;
    }

    .user-avatar {
      width: 28px;
      height: 28px;
      border-radius: 50%;
      background: #e5e5e5;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 11px;
      font-weight: 600;
      color: #78716c;
    }

    .user-info span {
      font-size: 13px;
      color: #78716c;
      font-weight: 500;
    }

    .logout-btn {
      width: 28px;
      height: 28px;
      border-radius: 50%;
      background: transparent;
      border: none;
      display: flex;
      align-items: center;
      justify-content: center;
      color: #a8a29e;
      cursor: pointer;

      mat-icon {
        font-size: 18px;
        width: 18px;
        height: 18px;
      }
    }

    section {
      margin-bottom: 24px;
    }

    label {
      display: block;
      font-size: 9px;
      text-transform: uppercase;
      letter-spacing: 0.2em;
      color: #a8a29e;
      margin-bottom: 12px;
    }

    .calendar-nav {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 12px;
    }

    .nav-btn {
      width: 36px;
      height: 36px;
      border: none;
      background: transparent;
      color: #a8a29e;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;

      &:disabled {
        opacity: 0.3;
        cursor: not-allowed;
      }
    }

    .month-label {
      font-size: 14px;
      font-weight: 500;
      color: #1C1917;
    }

    .calendar-grid {
      background: #fafaf9;
      border-radius: 16px;
      padding: 16px;
    }

    .weekday-header {
      display: grid;
      grid-template-columns: repeat(7, 1fr);
      gap: 4px;
      margin-bottom: 8px;

      span {
        text-align: center;
        font-size: 10px;
        color: #a8a29e;
        font-weight: 500;
        padding: 8px 0;
      }
    }

    .days-grid {
      display: grid;
      grid-template-columns: repeat(7, 1fr);
      gap: 4px;
    }

    .cal-day {
      aspect-ratio: 1;
      border: none;
      border-radius: 10px;
      font-size: 13px;
      font-weight: 500;
      cursor: pointer;
      transition: all 0.2s ease;

      &.available {
        background: #D1FAE5;
        color: #065F46;
      }

      &.limited {
        background: #FEF3C7;
        color: #92400E;
      }

      &.full {
        background: #FEE2E2;
        color: #991B1B;
        cursor: not-allowed;
      }

      &.closed {
        background: #E5E5E5;
        color: #737373;
        text-decoration: line-through;
        cursor: not-allowed;
      }

      &.past, &.disabled {
        background: transparent;
        color: #d6d3d1;
        cursor: not-allowed;
      }

      &.today:not(.selected) {
        outline: 2px solid #1C1917;
        outline-offset: -2px;
      }

      &.selected {
        background: #1C1917 !important;
        color: white !important;
        font-weight: 700;
      }
    }

    .legend {
      display: flex;
      flex-wrap: wrap;
      justify-content: center;
      gap: 12px;
      margin-top: 16px;
    }

    .legend-item {
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 9px;
      color: #78716c;
    }

    .dot {
      width: 12px;
      height: 12px;
      border-radius: 4px;

      &.available { background: #D1FAE5; }
      &.limited { background: #FEF3C7; }
      &.full { background: #FEE2E2; }
      &.closed { background: #E5E5E5; }
    }

    .selected-date-display {
      background: #1C1917;
      color: white;
      text-align: center;
      padding: 14px;
      border-radius: 12px;
      margin-top: 16px;
      font-size: 13px;
      font-weight: 500;
    }

    .loading-slots, .closed-message {
      text-align: center;
      padding: 24px;
      color: #a8a29e;

      mat-icon {
        font-size: 24px;
        width: 24px;
        height: 24px;
      }

      .spin {
        animation: spin 1s linear infinite;
      }

      p {
        margin-top: 8px;
        font-size: 13px;
      }

      .loading-hint {
        font-size: 11px;
        color: #d6d3d1;
      }
    }

    .error-slots {
      text-align: center;
      padding: 24px;
      background: #fafaf9;
      border-radius: 16px;
      color: #a8a29e;

      mat-icon {
        font-size: 32px;
        width: 32px;
        height: 32px;
        color: #d6d3d1;
      }

      p {
        margin-top: 12px;
        font-size: 13px;
      }

      .retry-btn {
        margin-top: 12px;
        display: inline-flex;
        align-items: center;
        gap: 6px;
        padding: 10px 20px;
        background: #1C1917;
        color: white;
        border: none;
        border-radius: 50px;
        font-size: 12px;
        cursor: pointer;

        mat-icon {
          font-size: 16px;
          width: 16px;
          height: 16px;
          color: white;
        }
      }
    }

    @keyframes spin {
      from { transform: rotate(0deg); }
      to { transform: rotate(360deg); }
    }

    .closed-message {
      background: #FEF2F2;
      border-radius: 16px;

      .closed-title {
        color: #DC2626;
        font-weight: 500;
        font-size: 14px;
      }

      .closed-reason {
        color: #F87171;
        font-size: 12px;
      }
    }

    .slots-grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 8px;
    }

    .slot-btn {
      padding: 12px 8px;
      border-radius: 12px;
      border: none;
      cursor: pointer;
      transition: all 0.2s ease;
      text-align: center;

      .slot-time {
        display: block;
        font-size: 14px;
        font-weight: 500;
        margin-bottom: 2px;
      }

      .slot-status {
        display: block;
        font-size: 10px;
      }

      &.available {
        background: #ECFDF5;
        .slot-time { color: #059669; }
        .slot-status { color: #10B981; }
      }

      &.full {
        background: #FEF2F2;
        .slot-time { color: #F87171; text-decoration: line-through; }
        .slot-status { color: #EF4444; }
        cursor: not-allowed;
      }

      &.selected {
        background: #1C1917;
        box-shadow: 0 4px 12px rgba(28, 25, 23, 0.3);
        .slot-time, .slot-status { color: white; text-decoration: none; }
      }
    }

    .guest-counter {
      display: flex;
      align-items: center;
      justify-content: space-between;
      border: 1px solid #f5f5f4;
      border-radius: 16px;
      padding: 8px;
    }

    .counter-btn {
      width: 48px;
      height: 48px;
      border: none;
      background: transparent;
      font-size: 20px;
      color: #a8a29e;
      cursor: pointer;

      &:disabled {
        opacity: 0.3;
        cursor: not-allowed;
      }

      &:active:not(:disabled) {
        color: #1C1917;
      }
    }

    .guest-count {
      font-size: 16px;
      font-weight: 500;
      color: #1C1917;
    }

    textarea {
      width: 100%;
      padding: 16px;
      background: #fafaf9;
      border: none;
      border-radius: 16px;
      font-size: 14px;
      color: #1C1917;
      resize: none;
      font-family: inherit;
      outline: none;

      &::placeholder {
        color: #a8a29e;
      }
    }

    .price-section {
      padding-top: 16px;
      border-top: 1px solid #fafaf9;
    }

    .price-row {
      display: flex;
      justify-content: space-between;
      align-items: flex-end;
    }

    .price-label {
      font-size: 9px;
      text-transform: uppercase;
      letter-spacing: 0.2em;
      color: #a8a29e;
      margin-bottom: 4px;
    }

    .price-value {
      font-size: 14px;
      font-weight: 500;
      color: #78716c;
    }

    .price-total {
      text-align: right;
    }

    .total-value {
      font-size: 24px;
      font-weight: 300;
      color: #1C1917;
    }

    .submit-btn {
      width: 100%;
      padding: 20px;
      background: #1C1917;
      color: white;
      border: none;
      border-radius: 16px;
      font-size: 10px;
      font-weight: 500;
      text-transform: uppercase;
      letter-spacing: 0.4em;
      cursor: pointer;
      box-shadow: 0 10px 30px rgba(28, 25, 23, 0.2);
      margin-top: 8px;

      &:disabled {
        background: #a8a29e;
        cursor: not-allowed;
        box-shadow: none;
      }
    }

    .success-screen {
      text-align: center;
      padding: 80px 24px;

      .success-divider {
        width: 40px;
        height: 1px;
        background: #1C1917;
        margin: 0 auto 40px;
      }

      h2 {
        font-size: 20px;
        font-weight: 300;
        text-transform: uppercase;
        letter-spacing: 0.3em;
        color: #1C1917;
        margin-bottom: 24px;
      }

      .success-summary {
        font-size: 12px;
        color: #78716c;
        line-height: 2;

        b {
          color: #1C1917;
        }
      }

      .back-btn {
        margin-top: 48px;
        background: transparent;
        border: none;
        font-size: 9px;
        text-transform: uppercase;
        letter-spacing: 0.2em;
        color: #a8a29e;
        cursor: pointer;
        padding-bottom: 4px;
        border-bottom: 1px solid transparent;

        &:hover {
          color: #1C1917;
          border-bottom-color: #1C1917;
        }
      }
    }
  `]
})
export class ReservationComponent implements OnInit {
  private apiService = inject(ApiService);
  authService = inject(AuthService);
  private dialog = inject(MatDialog);
  private snackBar = inject(MatSnackBar);
  private cdr = inject(ChangeDetectorRef);
  private ngZone = inject(NgZone);
  readonly i18n = inject(I18nService);

  // Calendar
  currentMonth = new Date().getMonth();
  currentYear = new Date().getFullYear();
  calendarDays: CalendarDay[] = [];
  monthNames = ['Siječanj', 'Veljača', 'Ožujak', 'Travanj', 'Svibanj', 'Lipanj',
                'Srpanj', 'Kolovoz', 'Rujan', 'Listopad', 'Studeni', 'Prosinac'];
  monthNamesGenitive = ['Siječnja', 'Veljače', 'Ožujka', 'Travnja', 'Svibnja', 'Lipnja',
                        'Srpnja', 'Kolovoza', 'Rujna', 'Listopada', 'Studenog', 'Prosinca'];
  dayNames = ['Nedjelja', 'Ponedjeljak', 'Utorak', 'Srijeda', 'Četvrtak', 'Petak', 'Subota'];
  weekdays = ['Pon', 'Uto', 'Sri', 'Čet', 'Pet', 'Sub', 'Ned'];

  today = new Date();
  maxDate = new Date(2026, 11, 31);

  // State
  selectedDate: string | null = null;
  selectedSlot: string | null = null;
  slots: TimeSlot[] = [];
  loadingSlots = false;
  slotsError = false;
  isClosed = false;
  closedReason = '';
  guests = 2;
  notes = '';
  loading = false;
  success = false;
  successMessage = '';

  get canGoPrev(): boolean {
    return this.currentYear > this.today.getFullYear() ||
           (this.currentYear === this.today.getFullYear() && this.currentMonth > this.today.getMonth());
  }

  get canGoNext(): boolean {
    return this.currentYear < 2026 || (this.currentYear === 2026 && this.currentMonth < 11);
  }

  get canSubmit(): boolean {
    return !!this.selectedDate && !!this.selectedSlot;
  }

  ngOnInit() {
    this.today.setHours(0, 0, 0, 0);
    this.buildCalendar();

    // Show auth dialog immediately if not logged in
    if (!this.authService.currentUser) {
      setTimeout(() => this.showAuthDialog(), 100);
    }

    // Auto-select today and load slots first
    const todayStr = this.formatDate(this.today);
    this.selectedDate = todayStr;
    this.loadSlots(todayStr);

    // Load month availability after a delay to not overwhelm the API on cold start
    setTimeout(() => this.loadMonthAvailability(), 2000);
  }

  showAuthDialog() {
    this.dialog.open(AuthDialogComponent, {
      maxWidth: '100vw',
      maxHeight: '100vh',
      width: '100%',
      height: '100%',
      panelClass: 'fullscreen-dialog',
      disableClose: false
    }).afterClosed().subscribe(result => {
      this.cdr.detectChanges();
    });
  }

  prevMonth() {
    if (!this.canGoPrev) return;
    this.currentMonth--;
    if (this.currentMonth < 0) {
      this.currentMonth = 11;
      this.currentYear--;
    }
    this.buildCalendar();
    this.loadMonthAvailability();
  }

  nextMonth() {
    if (!this.canGoNext) return;
    this.currentMonth++;
    if (this.currentMonth > 11) {
      this.currentMonth = 0;
      this.currentYear++;
    }
    this.buildCalendar();
    this.loadMonthAvailability();
  }

  buildCalendar() {
    this.calendarDays = [];
    const firstDay = new Date(this.currentYear, this.currentMonth, 1);
    let startDay = firstDay.getDay() - 1;
    if (startDay < 0) startDay = 6;

    const daysInMonth = new Date(this.currentYear, this.currentMonth + 1, 0).getDate();

    // Empty cells
    for (let i = 0; i < startDay; i++) {
      this.calendarDays.push({
        date: new Date(),
        day: 0,
        dateStr: '',
        status: 'disabled',
        isToday: false,
        isSelected: false
      });
    }

    // Days
    for (let day = 1; day <= daysInMonth; day++) {
      const date = new Date(this.currentYear, this.currentMonth, day);
      const dateStr = this.formatDate(date);
      const isPast = date < this.today;
      const isToday = date.toDateString() === this.today.toDateString();

      this.calendarDays.push({
        date,
        day,
        dateStr,
        status: isPast ? 'past' : 'available',
        isToday,
        isSelected: this.selectedDate === dateStr
      });
    }
  }

  loadMonthAvailability() {
    // Use calendar endpoint to get all days at once instead of individual requests
    const firstDay = new Date(this.currentYear, this.currentMonth, 1);
    const lastDay = new Date(this.currentYear, this.currentMonth + 1, 0);
    const startDate = this.formatDate(firstDay);
    const endDate = this.formatDate(lastDay);

    this.apiService.getCalendarStatus(startDate, endDate).subscribe({
      next: (data) => {
        this.ngZone.run(() => {
          if (!data || data.length === 0) return;

          data.forEach((dayData: any) => {
            const day = this.calendarDays.find(d => d.dateStr === dayData.date);
            if (!day || day.status === 'disabled' || day.status === 'past') return;

            if (dayData.isClosed) {
              day.status = 'closed';
            } else if (dayData.availableSlots === 0) {
              day.status = 'full';
            } else if (dayData.availableSlots < dayData.totalSlots / 2) {
              day.status = 'limited';
            } else {
              day.status = 'available';
            }
          });
          this.cdr.detectChanges();
        });
      },
      error: () => {
        // Silently fail - days will remain as 'available'
      }
    });
  }

  selectDate(day: CalendarDay) {
    if (day.status === 'disabled' || day.status === 'past' || day.status === 'closed' || day.status === 'full') {
      return;
    }

    this.calendarDays.forEach(d => d.isSelected = false);
    day.isSelected = true;
    this.selectedDate = day.dateStr;
    this.selectedSlot = null;
    this.loadSlots(day.dateStr);
  }

  loadSlots(dateStr: string) {
    this.loadingSlots = true;
    this.slotsError = false;
    this.isClosed = false;
    this.slots = [];
    this.cdr.detectChanges();

    this.apiService.getAvailableSlots(dateStr).subscribe({
      next: (data) => {
        this.ngZone.run(() => {
          this.loadingSlots = false;
          this.slotsError = false;
          if (data.isClosed) {
            this.isClosed = true;
            this.closedReason = data.reason || '';
          } else {
            this.slots = data.allSlots || data.slots || [];
          }
          this.cdr.detectChanges();
        });
      },
      error: () => {
        this.ngZone.run(() => {
          this.loadingSlots = false;
          this.slotsError = true;
          this.cdr.detectChanges();
        });
      }
    });
  }

  selectSlot(time: string) {
    this.selectedSlot = time;
  }

  updateGuests(delta: number) {
    const newValue = this.guests + delta;
    if (newValue >= 1 && newValue <= 8) {
      this.guests = newValue;
    }
  }

  formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  formatSelectedDate(): string {
    if (!this.selectedDate) return '';
    const date = new Date(this.selectedDate + 'T12:00:00');
    const dayName = this.dayNames[date.getDay()];
    const day = date.getDate();
    const month = this.monthNamesGenitive[date.getMonth()];
    const year = date.getFullYear();
    return `${dayName}, ${day}. ${month} ${year}`;
  }

  logout() {
    this.authService.logout().subscribe();
  }

  submitReservation() {
    if (!this.authService.currentUser) {
      this.dialog.open(AuthDialogComponent, {
        maxWidth: '100vw',
        maxHeight: '100vh',
        width: '100%',
        height: '100%',
        panelClass: 'fullscreen-dialog'
      }).afterClosed().subscribe(result => {
        if (result) {
          this.submitReservation();
        }
      });
      return;
    }

    if (!this.selectedDate || !this.selectedSlot) return;

    this.loading = true;

    const reservation: ReservationRequest = {
      date: this.selectedDate,
      time: this.selectedSlot,
      guests: this.guests,
      specialRequests: this.notes || undefined
    };

    this.apiService.createReservation(reservation).subscribe({
      next: () => {
        this.loading = false;
        this.success = true;

        const date = new Date(this.selectedDate + 'T12:00:00');
        const dayName = this.dayNames[date.getDay()];
        const day = date.getDate();
        const month = this.monthNamesGenitive[date.getMonth()];
        const year = date.getFullYear();
        const total = (this.guests * 95).toFixed(2).replace('.', ',');

        this.successMessage = `
          Vaša rezervacija za <b>${this.guests} ${this.guests === 1 ? 'osobu' : this.guests < 5 ? 'osobe' : 'osoba'}</b> je zaprimljena.<br><br>
          <span style="color:#a8a29e;text-transform:uppercase;letter-spacing:0.2em;font-size:10px">Datum:</span><br>
          <b>${dayName}, ${day}. ${month} ${year}</b><br><br>
          <span style="color:#a8a29e;text-transform:uppercase;letter-spacing:0.2em;font-size:10px">Termin:</span><br>
          <b>${this.selectedSlot}</b><br><br>
          <span style="color:#a8a29e;text-transform:uppercase;letter-spacing:0.2em;font-size:10px">Ukupni iznos:</span><br>
          <span style="font-size:16px">${total} €</span><br><br>
          <span style="color:#a8a29e;font-size:9px">Potvrda je poslana na ${this.authService.currentUser?.email}</span>
        `;
      },
      error: (err) => {
        this.loading = false;
        this.snackBar.open(err.error?.error || 'Greška pri rezervaciji', 'OK', { duration: 3000 });
      }
    });
  }
}
