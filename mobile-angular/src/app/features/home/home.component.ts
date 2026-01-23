import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule, RouterModule, MatButtonModule, MatIconModule],
  template: `
    <div class="home-page">
      <!-- Hero Section -->
      <section class="hero">
        <img src="https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?auto=format&fit=crop&q=80&w=2070"
             alt="Restaurant" class="hero-bg">
        <div class="hero-overlay"></div>
        <div class="hero-content">
          <p class="season">Zagreb — Sezona 2026</p>
          <h1>Okusi tišine.</h1>
          <a routerLink="/reservation" class="cta-button">
            Rezervirajte svoj stol
          </a>
        </div>
      </section>

      <!-- Philosophy Section -->
      <section class="philosophy">
        <p class="label">Filozofija</p>
        <h2>Minimalizam na tanjuru,<br>maksimalizam u okusu.</h2>
        <p class="description">
          Aura nije samo restoran, već putovanje kroz osjetila.
          Svaka namirnica u sezoni 2026. pažljivo je odabrana s lokalnih OPG-ova,
          tretirana s poštovanjem i pretvorena u umjetnost.
        </p>
      </section>

      <!-- Image Section -->
      <section class="image-section">
        <img src="https://images.unsplash.com/photo-1559339352-11d035aa65de?auto=format&fit=crop&q=80&w=1974"
             alt="Fine Dining" class="feature-image">
      </section>

      <!-- Quote Section -->
      <section class="quote-section">
        <div class="quote-card">
          <p>"Hrana koja priča priču o zemlji, moru i ljudima."</p>
        </div>
      </section>

      <!-- CTA Section -->
      <section class="cta-section">
        <h3>Pridružite nam se</h3>
        <a routerLink="/reservation" class="cta-button-dark">
          Osigurajte termin
        </a>
      </section>

      <!-- Info Section -->
      <section class="info-section">
        <div class="info-item">
          <mat-icon>place</mat-icon>
          <p>Trg Kralja Tomislava 1, Zagreb</p>
        </div>
        <div class="info-item">
          <mat-icon>schedule</mat-icon>
          <p>Utorak - Subota, 18:00 - 00:00</p>
        </div>
      </section>

      <!-- Footer -->
      <footer class="footer">
        <p class="logo">AURA</p>
        <p class="copyright">© 2026 Aura Fine Dining</p>
      </footer>
    </div>
  `,
  styles: [`
    .home-page {
      background: #fafaf9;
    }

    .hero {
      position: relative;
      height: 85vh;
      display: flex;
      align-items: center;
      justify-content: center;
      overflow: hidden;
    }

    .hero-bg {
      position: absolute;
      inset: 0;
      width: 100%;
      height: 100%;
      object-fit: cover;
    }

    .hero-overlay {
      position: absolute;
      inset: 0;
      background: linear-gradient(to bottom, rgba(0,0,0,0.3), rgba(0,0,0,0.7));
    }

    .hero-content {
      position: relative;
      text-align: center;
      color: white;
      padding: 0 24px;
    }

    .season {
      font-size: 10px;
      text-transform: uppercase;
      letter-spacing: 0.5em;
      opacity: 0.8;
      margin-bottom: 16px;
    }

    h1 {
      font-size: 36px;
      font-weight: 300;
      font-style: italic;
      letter-spacing: -0.02em;
      margin-bottom: 32px;
    }

    .cta-button {
      display: inline-block;
      border: 1px solid white;
      padding: 16px 32px;
      font-size: 10px;
      text-transform: uppercase;
      letter-spacing: 0.3em;
      color: white;
      text-decoration: none;
      transition: all 0.3s ease;

      &:active {
        background: white;
        color: black;
      }
    }

    .philosophy {
      padding: 64px 24px;
      text-align: center;
    }

    .label {
      font-size: 10px;
      text-transform: uppercase;
      letter-spacing: 0.4em;
      color: #a8a29e;
      margin-bottom: 16px;
    }

    h2 {
      font-size: 24px;
      font-weight: 300;
      line-height: 1.4;
      color: #1C1917;
      margin-bottom: 24px;
    }

    .description {
      font-size: 14px;
      color: #78716c;
      font-weight: 300;
      line-height: 1.7;
      max-width: 400px;
      margin: 0 auto;
    }

    .image-section {
      padding: 0 24px 48px;
    }

    .feature-image {
      width: 100%;
      height: 300px;
      object-fit: cover;
      border-radius: 16px;
      box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
    }

    .quote-section {
      padding: 0 24px 48px;
    }

    .quote-card {
      background: white;
      padding: 32px 24px;
      border-radius: 16px;
      text-align: center;

      p {
        font-size: 18px;
        font-style: italic;
        font-weight: 300;
        color: #1C1917;
        line-height: 1.6;
      }
    }

    .cta-section {
      text-align: center;
      padding: 48px 24px;

      h3 {
        font-size: 20px;
        font-weight: 300;
        text-transform: uppercase;
        letter-spacing: 0.2em;
        margin-bottom: 24px;
        color: #1C1917;
      }
    }

    .cta-button-dark {
      display: inline-block;
      background: #1C1917;
      color: white;
      padding: 20px 48px;
      border-radius: 50px;
      font-size: 10px;
      text-transform: uppercase;
      letter-spacing: 0.3em;
      text-decoration: none;
      box-shadow: 0 10px 30px rgba(28, 25, 23, 0.2);
    }

    .info-section {
      padding: 32px 24px;
      display: flex;
      flex-direction: column;
      gap: 16px;
      align-items: center;
    }

    .info-item {
      display: flex;
      align-items: center;
      gap: 12px;
      color: #78716c;

      mat-icon {
        font-size: 20px;
        width: 20px;
        height: 20px;
        color: #a8a29e;
      }

      p {
        font-size: 12px;
        text-transform: uppercase;
        letter-spacing: 0.1em;
      }
    }

    .footer {
      text-align: center;
      padding: 48px 24px 100px;
      border-top: 1px solid #e5e5e5;
    }

    .logo {
      font-size: 20px;
      font-weight: 300;
      letter-spacing: 0.3em;
      color: #d6d3d1;
      margin-bottom: 12px;
    }

    .copyright {
      font-size: 9px;
      text-transform: uppercase;
      letter-spacing: 0.2em;
      color: #a8a29e;
    }
  `]
})
export class HomeComponent {}
