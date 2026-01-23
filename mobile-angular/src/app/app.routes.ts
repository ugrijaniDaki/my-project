import { Routes } from '@angular/router';
import { BottomNavComponent } from './layout/bottom-nav.component';

export const routes: Routes = [
  {
    path: '',
    component: BottomNavComponent,
    children: [
      { path: '', redirectTo: 'home', pathMatch: 'full' },
      {
        path: 'home',
        loadComponent: () => import('./features/home/home.component')
          .then(m => m.HomeComponent)
      },
      {
        path: 'menu',
        loadComponent: () => import('./features/menu/menu.component')
          .then(m => m.MenuComponent)
      },
      {
        path: 'reservation',
        loadComponent: () => import('./features/reservation/reservation.component')
          .then(m => m.ReservationComponent)
      }
    ]
  },
  { path: '**', redirectTo: 'home' }
];
