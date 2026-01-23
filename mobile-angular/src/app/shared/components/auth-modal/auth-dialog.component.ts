import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatDialogRef, MatDialogModule } from '@angular/material/dialog';
import { MatTabsModule } from '@angular/material/tabs';
import { AuthService } from '../../../core/services/auth.service';

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
            <h2>Prijava</h2>
            <p>Prijavite se za nastavak</p>
          </div>

          <form class="auth-form" (ngSubmit)="login()">
            <input type="email" [(ngModel)]="loginEmail" name="email"
                   placeholder="Email adresa" required class="form-input">
            <input type="password" [(ngModel)]="loginPassword" name="password"
                   placeholder="Lozinka" required class="form-input">

            @if (error) {
              <div class="error-message">{{ error }}</div>
            }

            <button type="submit" class="submit-btn" [disabled]="loading">
              {{ loading ? 'Učitavam...' : 'Prijavi se' }}
            </button>
          </form>

          <div class="switch-mode">
            <p>Nemate račun?</p>
            <button (click)="mode = 'register'">Registrirajte se</button>
          </div>
        </div>
      }

      <!-- Register Form -->
      @if (mode === 'register') {
        <div class="form-container">
          <div class="form-title">
            <h2>Registracija</h2>
            <p>Kreirajte račun za rezervacije</p>
          </div>

          <form class="auth-form" (ngSubmit)="register()">
            <input type="text" [(ngModel)]="regName" name="name"
                   placeholder="Ime i prezime" required class="form-input">
            <input type="email" [(ngModel)]="regEmail" name="email"
                   placeholder="Email adresa" required class="form-input">
            <input type="tel" [(ngModel)]="regPhone" name="phone"
                   placeholder="Telefon" required class="form-input">
            <input type="password" [(ngModel)]="regPassword" name="password"
                   placeholder="Lozinka (min 6 znakova)" required minlength="6" class="form-input">

            @if (error) {
              <div class="error-message">{{ error }}</div>
            }

            <button type="submit" class="submit-btn" [disabled]="loading">
              {{ loading ? 'Učitavam...' : 'Registriraj se' }}
            </button>
          </form>

          <div class="switch-mode">
            <p>Imate račun?</p>
            <button (click)="mode = 'login'">Prijavite se</button>
          </div>
        </div>
      }
    </div>
  `,
  styles: [`
    .auth-dialog {
      background: white;
      min-height: 100vh;
      padding: 20px;
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
      this.error = 'Molimo popunite sva polja';
      return;
    }

    this.loading = true;
    this.error = '';

    this.authService.login(this.loginEmail, this.loginPassword).subscribe({
      next: () => {
        this.loading = false;
        this.dialogRef.close(true);
      },
      error: (err) => {
        this.loading = false;
        this.error = err.error?.error || 'Greška pri prijavi';
      }
    });
  }

  register() {
    if (!this.regName || !this.regEmail || !this.regPhone || !this.regPassword) {
      this.error = 'Molimo popunite sva polja';
      return;
    }

    if (this.regPassword.length < 6) {
      this.error = 'Lozinka mora imati najmanje 6 znakova';
      return;
    }

    this.loading = true;
    this.error = '';

    this.authService.register({
      name: this.regName,
      email: this.regEmail,
      phone: this.regPhone,
      password: this.regPassword
    }).subscribe({
      next: () => {
        this.loading = false;
        this.dialogRef.close(true);
      },
      error: (err) => {
        this.loading = false;
        this.error = err.error?.error || 'Greška pri registraciji';
      }
    });
  }
}
