import { bootstrapApplication } from '@angular/platform-browser';
import { appConfig } from './app/app.config';
import { AppComponent } from './app/app';

bootstrapApplication(AppComponent, appConfig)
  .catch((err) => {
    console.error('Bootstrap error:', err);
    // Show error to user
    const loadingEl = document.querySelector('.app-loading');
    if (loadingEl) {
      loadingEl.innerHTML = `
        <div style="text-align:center;padding:20px;">
          <p style="color:#dc2626;font-size:14px;margin-bottom:12px;">Greška pri učitavanju</p>
          <button onclick="location.reload()" style="padding:12px 24px;background:#1C1917;color:white;border:none;border-radius:50px;font-size:12px;cursor:pointer;">
            Pokušaj ponovo
          </button>
        </div>
      `;
    }
  });
