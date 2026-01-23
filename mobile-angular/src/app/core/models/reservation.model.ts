export interface TimeSlot {
  time: string;
  available: number;
  maxReservations: number;
}

export interface ScheduleResponse {
  isClosed: boolean;
  reason?: string;
  openTime?: string;
  closeTime?: string;
  slots: TimeSlot[];
  allSlots: TimeSlot[];
}

export interface CalendarDay {
  date: string;
  isClosed: boolean;
  reason?: string;
  availableSlots: number;
  totalSlots: number;
  status: 'available' | 'limited' | 'full' | 'closed' | 'past';
}

export interface ReservationRequest {
  date: string;
  time: string;
  guests: number;
  specialRequests?: string;
}

export interface Reservation {
  id: number;
  date: string;
  time: string;
  guests: number;
  tableNumber?: number;
  status: string;
  specialRequests?: string;
  adminNotes?: string;
  createdAt: string;
}

export interface GuestOrderRequest {
  customerName: string;
  deliveryAddress: string;
  phone: string;
  notes?: string;
  items: OrderItem[];
}

export interface OrderItem {
  menuItemId: number;
  quantity: number;
  notes?: string;
}

export interface OrderResponse {
  id: number;
  totalAmount: number;
  status: string;
}
