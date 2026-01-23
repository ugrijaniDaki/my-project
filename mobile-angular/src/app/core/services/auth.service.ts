import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, Observable, of, tap, catchError, map } from 'rxjs';
import { User, RegisterRequest, LoginRequest, AuthResponse } from '../models/user.model';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private readonly baseUrl = 'https://my-project-r5ce.onrender.com';
  private readonly TOKEN_KEY = 'authToken';
  private readonly USER_KEY = 'authUser';

  private currentUserSubject = new BehaviorSubject<User | null>(null);
  currentUser$ = this.currentUserSubject.asObservable();
  isLoggedIn$ = this.currentUser$.pipe(map(user => !!user));

  constructor(private http: HttpClient) {
    this.loadSavedSession();
  }

  private loadSavedSession(): void {
    const token = localStorage.getItem(this.TOKEN_KEY);
    const userJson = localStorage.getItem(this.USER_KEY);

    if (token && userJson) {
      try {
        const user = JSON.parse(userJson);
        this.currentUserSubject.next(user);
        // Verify in background
        this.verifyToken().subscribe();
      } catch {
        this.clearSession();
      }
    }
  }

  getToken(): string | null {
    return localStorage.getItem(this.TOKEN_KEY);
  }

  get currentUser(): User | null {
    return this.currentUserSubject.value;
  }

  register(data: RegisterRequest): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(
      `${this.baseUrl}/api/auth/register`,
      data
    ).pipe(
      tap(response => this.saveSession(response))
    );
  }

  login(email: string, password: string): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(
      `${this.baseUrl}/api/auth/login`,
      { email, password }
    ).pipe(
      tap(response => this.saveSession(response))
    );
  }

  logout(): Observable<void> {
    const token = this.getToken();
    if (token) {
      return this.http.post<void>(
        `${this.baseUrl}/api/auth/logout`,
        {},
        { headers: { 'Authorization': `Bearer ${token}` } }
      ).pipe(
        tap(() => this.clearSession()),
        catchError(() => {
          this.clearSession();
          return of(void 0);
        })
      );
    }
    this.clearSession();
    return of(void 0);
  }

  verifyToken(): Observable<boolean> {
    const token = this.getToken();
    if (!token) {
      return of(false);
    }

    return this.http.get<{ user: User }>(
      `${this.baseUrl}/api/auth/verify`,
      { headers: { 'Authorization': `Bearer ${token}` } }
    ).pipe(
      tap(response => {
        this.currentUserSubject.next(response.user);
        localStorage.setItem(this.USER_KEY, JSON.stringify(response.user));
      }),
      map(() => true),
      catchError(() => {
        this.clearSession();
        return of(false);
      })
    );
  }

  private saveSession(response: AuthResponse): void {
    localStorage.setItem(this.TOKEN_KEY, response.token);
    localStorage.setItem(this.USER_KEY, JSON.stringify(response.user));
    this.currentUserSubject.next(response.user);
  }

  private clearSession(): void {
    localStorage.removeItem(this.TOKEN_KEY);
    localStorage.removeItem(this.USER_KEY);
    this.currentUserSubject.next(null);
  }
}
