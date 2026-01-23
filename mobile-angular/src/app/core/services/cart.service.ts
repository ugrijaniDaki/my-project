import { Injectable } from '@angular/core';
import { BehaviorSubject, map } from 'rxjs';
import { MenuItem, CartItem } from '../models/menu-item.model';

@Injectable({
  providedIn: 'root'
})
export class CartService {
  private readonly CART_KEY = 'auraCart';

  private cartItemsSubject = new BehaviorSubject<CartItem[]>([]);
  cartItems$ = this.cartItemsSubject.asObservable();

  totalItems$ = this.cartItems$.pipe(
    map(items => items.reduce((sum, item) => sum + item.quantity, 0))
  );

  totalPrice$ = this.cartItems$.pipe(
    map(items => items.reduce((sum, item) => sum + item.price * item.quantity, 0))
  );

  constructor() {
    this.loadCart();
  }

  private loadCart(): void {
    const saved = localStorage.getItem(this.CART_KEY);
    if (saved) {
      try {
        const items = JSON.parse(saved);
        this.cartItemsSubject.next(items);
      } catch {
        this.cartItemsSubject.next([]);
      }
    }
  }

  private saveCart(): void {
    localStorage.setItem(this.CART_KEY, JSON.stringify(this.cartItemsSubject.value));
  }

  get cartItems(): CartItem[] {
    return this.cartItemsSubject.value;
  }

  addToCart(item: MenuItem): void {
    const items = [...this.cartItemsSubject.value];
    const existing = items.find(i => i.id === item.id);

    if (existing) {
      existing.quantity++;
    } else {
      items.push({ ...item, quantity: 1 });
    }

    this.cartItemsSubject.next(items);
    this.saveCart();
  }

  removeFromCart(itemId: number): void {
    const items = this.cartItemsSubject.value.filter(i => i.id !== itemId);
    this.cartItemsSubject.next(items);
    this.saveCart();
  }

  updateQuantity(itemId: number, delta: number): void {
    const items = [...this.cartItemsSubject.value];
    const item = items.find(i => i.id === itemId);

    if (item) {
      item.quantity += delta;
      if (item.quantity <= 0) {
        this.removeFromCart(itemId);
        return;
      }
    }

    this.cartItemsSubject.next(items);
    this.saveCart();
  }

  clearCart(): void {
    this.cartItemsSubject.next([]);
    this.saveCart();
  }

  getTotal(): number {
    return this.cartItemsSubject.value.reduce(
      (sum, item) => sum + item.price * item.quantity,
      0
    );
  }
}
