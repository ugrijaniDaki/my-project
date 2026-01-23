import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, timeout, retry, catchError, of } from 'rxjs';
import { MenuItem } from '../models/menu-item.model';
import {
  ScheduleResponse,
  ReservationRequest,
  Reservation,
  GuestOrderRequest,
  OrderResponse
} from '../models/reservation.model';

@Injectable({
  providedIn: 'root'
})
export class ApiService {
  private readonly baseUrl = 'https://my-project-r5ce.onrender.com';
  private readonly TIMEOUT = 60000; // 60 seconds for Render cold start

  constructor(private http: HttpClient) {}

  // Menu
  getMenuItems(): Observable<MenuItem[]> {
    return this.http.get<MenuItem[]>(`${this.baseUrl}/api/menu`).pipe(
      timeout(this.TIMEOUT),
      retry({ count: 2, delay: 1000 })
    );
  }

  // Schedule
  getAvailableSlots(date: string): Observable<ScheduleResponse> {
    return this.http.get<ScheduleResponse>(
      `${this.baseUrl}/api/schedule/available/${date}?_=${Date.now()}`
    ).pipe(
      timeout(this.TIMEOUT),
      retry({ count: 1, delay: 1000 })
    );
  }

  // Calendar status for multiple days (more efficient)
  getCalendarStatus(startDate: string, endDate: string): Observable<any[]> {
    return this.http.get<any[]>(
      `${this.baseUrl}/api/schedule/calendar/${startDate}/${endDate}`
    ).pipe(
      timeout(this.TIMEOUT),
      retry({ count: 1, delay: 1000 }),
      catchError(() => of([]))
    );
  }

  // Reservations
  createReservation(reservation: ReservationRequest): Observable<Reservation> {
    return this.http.post<Reservation>(
      `${this.baseUrl}/api/reservations`,
      reservation
    ).pipe(
      timeout(this.TIMEOUT)
    );
  }

  getMyReservations(): Observable<Reservation[]> {
    return this.http.get<Reservation[]>(`${this.baseUrl}/api/my-reservations`).pipe(
      timeout(this.TIMEOUT)
    );
  }

  // Orders
  createGuestOrder(order: GuestOrderRequest): Observable<OrderResponse> {
    return this.http.post<OrderResponse>(
      `${this.baseUrl}/api/orders/guest`,
      order
    ).pipe(
      timeout(this.TIMEOUT)
    );
  }
}
