import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet],
  template: `
    <div class="app-shell">
      <nav class="topnav">
        <span class="brand">Openbridge Identity Manager</span>
      </nav>
      <main>
        <router-outlet></router-outlet>
      </main>
    </div>
  `,
  styles: [`
    .app-shell { min-height: 100vh; background: #f8f9fa; }
    .topnav { background: #1a1a2e; color: #fff; padding: 12px 24px; font-size: 1.1rem; }
    .brand { font-weight: 600; }
    main { padding: 1rem; }
  `]
})
export class AppComponent {}
