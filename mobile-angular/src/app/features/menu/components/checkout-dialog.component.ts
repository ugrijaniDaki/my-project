import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatDialogRef, MatDialogModule } from '@angular/material/dialog';
import { MatInputModule } from '@angular/material/input';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { CartService } from '../../../core/services/cart.service';
import { ApiService } from '../../../core/services/api.service';
import { GuestOrderRequest } from '../../../core/models/reservation.model';

@Component({
  selector: 'app-checkout-dialog',
  standalone: true,
  imports: [
    CommonModule, FormsModule, MatButtonModule, MatIconModule,
    MatDialogModule, MatInputModule, MatFormFieldModule, MatSnackBarModule
  ],
  template: `
    <div class="checkout-dialog">
      @if (!success) {
        <!-- Header -->
        <div class="dialog-header">
          <button class="back-btn" (click)="close()">
            <mat-icon>arrow_back</mat-icon>
          </button>
        </div>

        <!-- Title -->
        <div class="dialog-title">
          <h2>Dostava</h2>
          <p>Unesite podatke za dostavu</p>
        </div>

        <!-- Form -->
        <form class="checkout-form" (ngSubmit)="submitOrder()">
          <input type="text" [(ngModel)]="firstName" name="firstName"
                 placeholder="Ime" required class="form-input">

          <input type="text" [(ngModel)]="lastName" name="lastName"
                 placeholder="Prezime" required class="form-input">

          <input type="tel" [(ngModel)]="phone" name="phone"
                 placeholder="Telefon" required class="form-input">

          <input type="text" [(ngModel)]="address" name="address"
                 placeholder="Adresa dostave" required class="form-input">

          <textarea [(ngModel)]="notes" name="notes" rows="2"
                    placeholder="Napomena (opcionalno)" class="form-input"></textarea>

          <!-- Order Summary -->
          <div class="order-summary">
            <div class="summary-header">
              <span>Vaša narudžba</span>
              <span>{{ (cartService.totalItems$ | async) }} artikala</span>
            </div>
            <div class="summary-items">
              @for (item of cartService.cartItems$ | async; track item.id) {
                <div class="summary-item">
                  <span>{{ item.quantity }}× {{ item.name }}</span>
                  <span>{{ (item.price * item.quantity).toFixed(2) }} €</span>
                </div>
              }
            </div>
            <div class="summary-total">
              <span>Ukupno</span>
              <span class="total">{{ (cartService.totalPrice$ | async)?.toFixed(2) }} €</span>
            </div>
          </div>

          @if (error) {
            <div class="error-message">{{ error }}</div>
          }

          <button type="submit" class="submit-btn" [disabled]="loading">
            {{ loading ? 'Šaljem...' : 'Potvrdi narudžbu' }}
          </button>
        </form>
      }

      @if (success) {
        <!-- Success State -->
        <div class="success-state">
          <div class="success-icon">
            <mat-icon>check</mat-icon>
          </div>
          <h3>Hvala vam!</h3>
          <p>Vaša narudžba je uspješno zaprimljena.<br>Uskoro ćemo vas kontaktirati.</p>
          <button class="ok-btn" (click)="close()">U redu</button>
        </div>
      }
    </div>
  `,
  styles: [`
    .checkout-dialog {
      background: white;
      min-height: 100vh;
      padding: 20px;
      padding-bottom: 40px;
    }

    .dialog-header {
      margin-bottom: 16px;
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

    .dialog-title {
      text-align: center;
      margin-bottom: 24px;

      h2 {
        font-size: 18px;
        font-weight: 500;
        text-transform: uppercase;
        letter-spacing: 0.3em;
        color: #1C1917;
        margin-bottom: 8px;
      }

      p {
        font-size: 14px;
        color: #a8a29e;
      }
    }

    .checkout-form {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .form-input {
      width: 100%;
      padding: 16px 20px;
      background: #f5f5f4;
      border: none;
      border-radius: 16px;
      font-size: 14px;
      color: #1C1917;
      outline: none;
      font-family: inherit;
      resize: none;

      &::placeholder {
        color: #a8a29e;
      }

      &:focus {
        box-shadow: 0 0 0 2px rgba(28, 25, 23, 0.1);
      }
    }

    .order-summary {
      background: #fafaf9;
      border-radius: 16px;
      padding: 16px;
      margin-top: 8px;
    }

    .summary-header {
      display: flex;
      justify-content: space-between;
      font-size: 12px;
      color: #78716c;
      margin-bottom: 12px;
    }

    .summary-items {
      max-height: 120px;
      overflow-y: auto;
      margin-bottom: 12px;
    }

    .summary-item {
      display: flex;
      justify-content: space-between;
      font-size: 13px;
      color: #78716c;
      margin-bottom: 6px;
    }

    .summary-total {
      display: flex;
      justify-content: space-between;
      padding-top: 12px;
      border-top: 1px solid #e5e5e5;
      font-size: 14px;

      span {
        color: #78716c;
      }

      .total {
        font-size: 18px;
        font-weight: 500;
        color: #1C1917;
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
      border-radius: 16px;
      font-size: 12px;
      font-weight: 500;
      text-transform: uppercase;
      letter-spacing: 0.2em;
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

    .success-state {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 80vh;
      text-align: center;
      padding: 40px 20px;
    }

    .success-icon {
      width: 64px;
      height: 64px;
      border-radius: 50%;
      background: #dcfce7;
      display: flex;
      align-items: center;
      justify-content: center;
      margin-bottom: 24px;

      mat-icon {
        font-size: 32px;
        width: 32px;
        height: 32px;
        color: #16a34a;
      }
    }

    h3 {
      font-size: 18px;
      font-weight: 500;
      text-transform: uppercase;
      letter-spacing: 0.2em;
      color: #1C1917;
      margin-bottom: 12px;
    }

    .success-state p {
      font-size: 14px;
      color: #a8a29e;
      line-height: 1.6;
      margin-bottom: 32px;
    }

    .ok-btn {
      width: 100%;
      max-width: 300px;
      padding: 18px;
      background: #1C1917;
      color: white;
      border: none;
      border-radius: 16px;
      font-size: 12px;
      font-weight: 500;
      text-transform: uppercase;
      letter-spacing: 0.2em;
      cursor: pointer;
    }
  `]
})
export class CheckoutDialogComponent {
  cartService = inject(CartService);
  private apiService = inject(ApiService);
  private dialogRef = inject(MatDialogRef<CheckoutDialogComponent>);
  private snackBar = inject(MatSnackBar);

  firstName = '';
  lastName = '';
  phone = '';
  address = '';
  notes = '';
  error = '';
  loading = false;
  success = false;

  close() {
    this.dialogRef.close();
  }

  submitOrder() {
    if (!this.firstName || !this.lastName || !this.phone || !this.address) {
      this.error = 'Molimo popunite sva obavezna polja';
      return;
    }

    this.loading = true;
    this.error = '';

    const order: GuestOrderRequest = {
      customerName: `${this.firstName} ${this.lastName}`,
      phone: this.phone,
      deliveryAddress: this.address,
      notes: this.notes,
      items: this.cartService.cartItems.map(item => ({
        menuItemId: item.id,
        quantity: item.quantity
      }))
    };

    this.apiService.createGuestOrder(order).subscribe({
      next: () => {
        this.cartService.clearCart();
        this.success = true;
        this.loading = false;
      },
      error: (err) => {
        this.loading = false;
        this.error = err.error?.error || 'Greška pri slanju narudžbe';
      }
    });
  }
}
