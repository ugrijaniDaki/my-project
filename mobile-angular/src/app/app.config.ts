import { ApplicationConfig, provideBrowserGlobalErrorListeners, isDevMode, APP_INITIALIZER, inject } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient, withInterceptors, HttpClient } from '@angular/common/http';
import { provideAnimationsAsync } from '@angular/platform-browser/animations/async';
import { provideServiceWorker } from '@angular/service-worker';
import { firstValueFrom, timeout, catchError, of } from 'rxjs';

import { routes } from './app.routes';
import { authInterceptor } from './core/interceptors/auth.interceptor';

// Wake up the server on app init (Render free tier cold start)
function wakeUpServer() {
  return () => {
    const http = inject(HttpClient);
    // Send a lightweight ping to wake up the server
    return firstValueFrom(
      http.get('https://my-project-r5ce.onrender.com/api/menu', { responseType: 'text' }).pipe(
        timeout(90000), // 90 second timeout for cold start
        catchError(() => of(null)) // Ignore errors, just wake up
      )
    );
  };
}

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes),
    provideHttpClient(withInterceptors([authInterceptor])),
    provideAnimationsAsync(),
    provideServiceWorker('ngsw-worker.js', {
      enabled: !isDevMode(),
      registrationStrategy: 'registerWhenStable:30000'
    }),
    {
      provide: APP_INITIALIZER,
      useFactory: wakeUpServer,
      multi: true
    }
  ]
};
