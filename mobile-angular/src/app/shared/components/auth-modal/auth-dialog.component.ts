import { Component, inject, ChangeDetectorRef, NgZone } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatDialogRef, MatDialogModule } from '@angular/material/dialog';
import { MatTabsModule } from '@angular/material/tabs';
import { AuthService } from '../../../core/services/auth.service';
import { I18nService } from '../../../core/services/i18n.service';

@Component({
  selector: 'app-auth-dialog',
  standalone: true,
  imports: [CommonModule, FormsModule, MatButtonModule, MatIconModule, MatDialogModule, MatTabsModule],
  template: `
    <div class="auth-dialog">
      <!-- Header -->
      <div class="dialog-header">
        <button class="back-btn" (click)="close()">
          <mat-icon>arrow_back</mat-icon>
        </button>
      </div>

      <!-- Login Form -->
      @if (mode === 'login') {
        <div class="form-container">
          <div class="form-title">
            <h2>{{ i18n.t().auth.loginTitle }}</h2>
            <p>{{ i18n.t().auth.loginSubtitle }}</p>
          </div>

          <form class="auth-form" (ngSubmit)="login()">
            <input type="email" [(ngModel)]="loginEmail" name="email"
                   [placeholder]="i18n.t().auth.email" required class="form-input">
            <input type="password" [(ngModel)]="loginPassword" name="password"
                   [placeholder]="i18n.t().auth.password" required class="form-input">

            @if (error) {
              <div class="error-message">{{ error }}</div>
            }

            <button type="submit" class="submit-btn" [disabled]="loading">
              {{ loading ? i18n.t().auth.loggingIn : i18n.t().auth.login }}
            </button>
          </form>

          <div class="switch-mode">
            <p>{{ i18n.t().auth.noAccount }}</p>
            <button (click)="mode = 'register'">{{ i18n.t().auth.register }}</button>
          </div>
        </div>
      }

      <!-- Register Form -->
      @if (mode === 'register') {
        <div class="form-container">
          <div class="form-title">
            <h2>{{ i18n.t().auth.registerTitle }}</h2>
            <p>{{ i18n.t().auth.registerSubtitle }}</p>
          </div>

          <form class="auth-form" (ngSubmit)="register()">
            <input type="text" [(ngModel)]="regName" name="name"
                   [placeholder]="i18n.t().auth.name" required class="form-input">
            <input type="email" [(ngModel)]="regEmail" name="email"
                   [placeholder]="i18n.t().auth.email" required class="form-input">
            <input type="tel" [(ngModel)]="regPhone" name="phone"
                   [placeholder]="i18n.t().auth.phone" required class="form-input">
            <input type="password" [(ngModel)]="regPassword" name="password"
                   [placeholder]="i18n.t().auth.passwordHint" required minlength="6" class="form-input">

            @if (error) {
              <div class="error-message">{{ error }}</div>
            }

            <button type="submit" class="submit-btn" [disabled]="loading">
              {{ loading ? i18n.t().auth.registering : i18n.t().auth.register }}
            </button>
          </form>

          <div class="switch-mode">
            <p>{{ i18n.t().auth.hasAccount }}</p>
            <button (click)="mode = 'login'">{{ i18n.t().auth.login }}</button>
          </div>
        </div>
      }
    </div>
  `,
  styles: [`
    .auth-dialog {
      background: white;
      min-height: 100vh;
      min-height: 100dvh;
      padding: 20px;
      padding-bottom: env(safe-area-inset-bottom, 20px);
      overflow-y: auto;
      -webkit-overflow-scrolling: touch;
    }

    .dialog-header {
      margin-bottom: 32px;
    }

    .back-btn {
      width: 40px;
      height: 40px;
      border-radius: 50%;
      background: #f5f5f4;
      border: none;
      display: flex;
      align-items: center;
      justify-content: center;
      color: #78716c;
      cursor: pointer;
    }

    .form-container {
      max-width: 400px;
      margin: 0 auto;
    }

    .form-title {
      text-align: center;
      margin-bottom: 32px;

      h2 {
        font-size: 20px;
        font-weight: 300;
        text-transform: uppercase;
        letter-spacing: 0.3em;
        color: #1C1917;
        margin-bottom: 8px;
      }

      p {
        font-size: 12px;
        color: #a8a29e;
      }
    }

    .auth-form {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .form-input {
      width: 100%;
      padding: 16px 20px;
      background: #fafaf9;
      border: none;
      border-radius: 12px;
      font-size: 14px;
      color: #1C1917;
      outline: none;
      font-family: inherit;

      &::placeholder {
        color: #a8a29e;
      }

      &:focus {
        box-shadow: 0 0 0 2px rgba(28, 25, 23, 0.1);
      }
    }

    .error-message {
      background: #fef2f2;
      color: #dc2626;
      padding: 12px 16px;
      border-radius: 12px;
      font-size: 13px;
      text-align: center;
    }

    .submit-btn {
      width: 100%;
      padding: 18px;
      background: #1C1917;
      color: white;
      border: none;
      border-radius: 12px;
      font-size: 10px;
      font-weight: 500;
      text-transform: uppercase;
      letter-spacing: 0.3em;
      cursor: pointer;
      margin-top: 8px;

      &:disabled {
        background: #a8a29e;
        cursor: not-allowed;
      }

      &:active:not(:disabled) {
        background: #292524;
      }
    }

    .switch-mode {
      text-align: center;
      margin-top: 32px;
      padding-top: 24px;
      border-top: 1px solid #f5f5f4;

      p {
        font-size: 12px;
        color: #a8a29e;
        margin-bottom: 8px;
      }

      button {
        background: none;
        border: none;
        font-size: 12px;
        color: #1C1917;
        font-weight: 500;
        cursor: pointer;
      }
    }
  `]
})
export class AuthDialogComponent {
  private authService = inject(AuthService);
  private dialogRef = inject(MatDialogRef<AuthDialogComponent>);
  private cdr = inject(ChangeDetectorRef);
  private ngZone = inject(NgZone);
  readonly i18n = inject(I18nService);

  mode: 'login' | 'register' = 'register';
  error = '';
  loading = false;

  // Login
  loginEmail = '';
  loginPassword = '';

  // Register
  regName = '';
  regEmail = '';
  regPhone = '';
  regPassword = '';

  close() {
    this.dialogRef.close(false);
  }

  login() {
    if (!this.loginEmail || !this.loginPassword) {
      this.error = this.i18n.t().auth.fillAllFields;
      this.cdr.detectChanges();
      return;
    }

    this.loading = true;
    this.error = '';
    this.cdr.detectChanges();

    this.authService.login(this.loginEmail, this.loginPassword).subscribe({
      next: () => {
        this.ngZone.run(() => {
          this.loading = false;
          this.cdr.detectChanges();
          this.dialogRef.close(true);
        });
      },
      error: (err) => {
        this.ngZone.run(() => {
          this.loading = false;
          this.error = err.error?.error || this.i18n.t().auth.loginError;
          this.cdr.detectChanges();
        });
      }
    });
  }

  register() {
    if (!this.regName || !this.regEmail || !this.regPhone || !this.regPassword) {
      this.error = this.i18n.t().auth.fillAllFields;
      this.cdr.detectChanges();
      return;
    }

    if (this.regPassword.length < 6) {
      this.error = this.i18n.t().auth.passwordTooShort;
      this.cdr.detectChanges();
      return;
    }

    this.loading = true;
    this.error = '';
    this.cdr.detectChanges();

    this.authService.register({
      name: this.regName,
      email: this.regEmail,
      phone: this.regPhone,
      password: this.regPassword
    }).subscribe({
      next: () => {
        this.ngZone.run(() => {
          this.loading = false;
          this.cdr.detectChanges();
          this.dialogRef.close(true);
        });
      },
      error: (err) => {
        this.ngZone.run(() => {
          this.loading = false;
          this.error = err.error?.error || this.i18n.t().auth.registerError;
          this.cdr.detectChanges();
        });
      }
    });
  }
}
