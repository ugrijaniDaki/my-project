import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, RouterOutlet } from '@angular/router';
import { MatTabsModule } from '@angular/material/tabs';
import { MatIconModule } from '@angular/material/icon';

@Component({
  selector: 'app-bottom-nav',
  standalone: true,
  imports: [CommonModule, RouterModule, RouterOutlet, MatTabsModule, MatIconModule],
  template: `
    <div class="app-container">
      <main class="content">
        <router-outlet></router-outlet>
      </main>

      <nav class="bottom-nav">
        <a routerLink="/home" routerLinkActive="active" class="nav-item">
          <mat-icon>home</mat-icon>
          <span>Početna</span>
        </a>
        <a routerLink="/menu" routerLinkActive="active" class="nav-item">
          <mat-icon>restaurant_menu</mat-icon>
          <span>Menu</span>
        </a>
        <a routerLink="/reservation" routerLinkActive="active" class="nav-item">
          <mat-icon>event</mat-icon>
          <span>Rezervacija</span>
        </a>
      </nav>
    </div>
  `,
  styles: [`
    .app-container {
      display: flex;
      flex-direction: column;
      min-height: 100vh;
      min-height: 100dvh;
      background: #fafaf9;
    }

    .content {
      flex: 1;
      overflow-y: auto;
      padding-bottom: 80px;
    }

    .bottom-nav {
      position: fixed;
      bottom: 0;
      left: 0;
      right: 0;
      height: 70px;
      background: white;
      display: flex;
      justify-content: space-around;
      align-items: center;
      box-shadow: 0 -4px 20px rgba(0, 0, 0, 0.08);
      border-top-left-radius: 24px;
      border-top-right-radius: 24px;
      padding-bottom: env(safe-area-inset-bottom, 0);
      z-index: 1000;
    }

    .nav-item {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 4px;
      padding: 8px 20px;
      text-decoration: none;
      color: #a8a29e;
      transition: all 0.2s ease;
      border-radius: 16px;

      mat-icon {
        font-size: 24px;
        width: 24px;
        height: 24px;
      }

      span {
        font-size: 10px;
        font-weight: 500;
        text-transform: uppercase;
        letter-spacing: 0.05em;
      }

      &.active {
        color: #1C1917;
        background: rgba(28, 25, 23, 0.05);

        mat-icon {
          transform: scale(1.1);
        }
      }
    }
  `]
})
export class BottomNavComponent {}
