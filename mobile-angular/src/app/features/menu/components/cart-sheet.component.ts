import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatBottomSheetRef } from '@angular/material/bottom-sheet';
import { MatDialogModule, MatDialog } from '@angular/material/dialog';
import { CartService } from '../../../core/services/cart.service';
import { CheckoutDialogComponent } from './checkout-dialog.component';

@Component({
  selector: 'app-cart-sheet',
  standalone: true,
  imports: [CommonModule, FormsModule, MatButtonModule, MatIconModule, MatDialogModule],
  template: `
    <div class="cart-sheet">
      <!-- Header -->
      <div class="sheet-header">
        <button class="back-btn" (click)="close()">
          <mat-icon>arrow_back</mat-icon>
        </button>
      </div>

      <!-- Title -->
      <div class="sheet-title">
        <h2>Košarica</h2>
        <p>{{ (cartService.totalItems$ | async) || 0 }} artikala</p>
      </div>

      <!-- Empty State -->
      @if ((cartService.cartItems$ | async)?.length === 0) {
        <div class="empty-state">
          <div class="empty-icon">
            <mat-icon>shopping_bag</mat-icon>
          </div>
          <p>Košarica je prazna</p>
        </div>
      }

      <!-- Cart Items -->
      @if ((cartService.cartItems$ | async)?.length ?? 0 > 0) {
        <div class="cart-items">
          @for (item of cartService.cartItems$ | async; track item.id) {
            <div class="cart-item">
              <div class="item-info">
                <h4>{{ item.name }}</h4>
                <p>{{ item.price.toFixed(2) }} €</p>
              </div>
              <div class="item-controls">
                <button class="qty-btn" (click)="updateQuantity(item.id, -1)">−</button>
                <span class="qty">{{ item.quantity }}</span>
                <button class="qty-btn" (click)="updateQuantity(item.id, 1)">+</button>
              </div>
              <button class="remove-btn" (click)="removeItem(item.id)">
                <mat-icon>close</mat-icon>
              </button>
            </div>
          }
        </div>

        <!-- Footer -->
        <div class="cart-footer">
          <div class="total-row">
            <span>Ukupno</span>
            <span class="total-price">{{ (cartService.totalPrice$ | async)?.toFixed(2) }} €</span>
          </div>
          <button class="checkout-btn" (click)="checkout()">
            Nastavi na narudžbu
          </button>
        </div>
      }
    </div>
  `,
  styles: [`
    .cart-sheet {
      background: white;
      border-top-left-radius: 32px;
      border-top-right-radius: 32px;
      max-height: 85vh;
      overflow: hidden;
      display: flex;
      flex-direction: column;
    }

    .sheet-header {
      padding: 20px 20px 8px;
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

    .sheet-title {
      text-align: center;
      padding: 0 20px 20px;

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

    .empty-state {
      padding: 48px 20px;
      text-align: center;

      .empty-icon {
        width: 64px;
        height: 64px;
        margin: 0 auto 16px;
        border-radius: 50%;
        background: #f5f5f4;
        display: flex;
        align-items: center;
        justify-content: center;

        mat-icon {
          font-size: 32px;
          width: 32px;
          height: 32px;
          color: #d6d3d1;
        }
      }

      p {
        color: #a8a29e;
        font-size: 14px;
      }
    }

    .cart-items {
      flex: 1;
      overflow-y: auto;
      padding: 0 20px;
      max-height: 40vh;
    }

    .cart-item {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 16px;
      background: #f5f5f4;
      border-radius: 16px;
      margin-bottom: 12px;
    }

    .item-info {
      flex: 1;
      min-width: 0;

      h4 {
        font-size: 14px;
        font-weight: 500;
        color: #1C1917;
        margin-bottom: 4px;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
      }

      p {
        font-size: 13px;
        color: #a8a29e;
      }
    }

    .item-controls {
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .qty-btn {
      width: 32px;
      height: 32px;
      border-radius: 50%;
      background: white;
      border: none;
      font-size: 18px;
      color: #78716c;
      cursor: pointer;

      &:active {
        background: #e5e5e5;
      }
    }

    .qty {
      font-size: 14px;
      font-weight: 600;
      color: #1C1917;
      min-width: 24px;
      text-align: center;
    }

    .remove-btn {
      width: 32px;
      height: 32px;
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

      &:active {
        color: #ef4444;
        background: #fef2f2;
      }
    }

    .cart-footer {
      padding: 20px;
      border-top: 1px solid #f5f5f4;
    }

    .total-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 16px;

      span {
        color: #78716c;
        font-size: 14px;
      }

      .total-price {
        font-size: 24px;
        font-weight: 500;
        color: #1C1917;
      }
    }

    .checkout-btn {
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

      &:active {
        background: #292524;
      }
    }
  `]
})
export class CartSheetComponent {
  cartService = inject(CartService);
  private bottomSheetRef = inject(MatBottomSheetRef<CartSheetComponent>);
  private dialog = inject(MatDialog);

  close() {
    this.bottomSheetRef.dismiss();
  }

  updateQuantity(id: number, delta: number) {
    this.cartService.updateQuantity(id, delta);
  }

  removeItem(id: number) {
    this.cartService.removeFromCart(id);
  }

  checkout() {
    this.bottomSheetRef.dismiss();
    this.dialog.open(CheckoutDialogComponent, {
      maxWidth: '100vw',
      maxHeight: '100vh',
      width: '100%',
      height: '100%',
      panelClass: 'fullscreen-dialog'
    });
  }
}
