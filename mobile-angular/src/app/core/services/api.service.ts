import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
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

  constructor(private http: HttpClient) {}

  // Menu
  getMenuItems(): Observable<MenuItem[]> {
    return this.http.get<MenuItem[]>(`${this.baseUrl}/api/menu`);
  }

  // Schedule
  getAvailableSlots(date: string): Observable<ScheduleResponse> {
    return this.http.get<ScheduleResponse>(
      `${this.baseUrl}/api/schedule/available/${date}?_=${Date.now()}`
    );
  }

  getCalendarStatus(startDate: string, endDate: string): Observable<any[]> {
    return this.http.get<any[]>(
      `${this.baseUrl}/api/schedule/calendar/${startDate}/${endDate}`
    );
  }

  // Reservations
  createReservation(reservation: ReservationRequest): Observable<Reservation> {
    return this.http.post<Reservation>(
      `${this.baseUrl}/api/reservations`,
      reservation
    );
  }

  getMyReservations(): Observable<Reservation[]> {
    return this.http.get<Reservation[]>(`${this.baseUrl}/api/my-reservations`);
  }

  // Orders
  createGuestOrder(order: GuestOrderRequest): Observable<OrderResponse> {
    return this.http.post<OrderResponse>(
      `${this.baseUrl}/api/orders/guest`,
      order
    );
  }
}
