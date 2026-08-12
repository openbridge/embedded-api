import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';

interface IdentityTypeCard {
  typeId: number;
  name: string;
  description: string;
  paths: { id: number; label: string; route: string }[];
}

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="dashboard">
      <div class="header">
        <h1>Amazon Remote Identity Manager</h1>
        <p class="subtitle">Create and manage remote identities for Amazon services</p>
      </div>

      <div class="cards">
        <div class="card" *ngFor="let type of identityTypes">
          <h2>{{ type.name }}</h2>
          <p>{{ type.description }}</p>
<div class="paths">
            <button *ngFor="let path of type.paths"
                    (click)="navigate(path.route, type.typeId)"
                    class="path-btn">
              {{ path.label }}
            </button>
          </div>
        </div>
      </div>

      <div class="actions">
        <button (click)="router.navigate(['/identities'])" class="secondary-btn">
          View Existing Identities
        </button>
      </div>
    </div>
  `,
  styles: [`
    .dashboard { max-width: 1000px; margin: 0 auto; padding: 2rem; }
    .header { text-align: center; margin-bottom: 2rem; }
    .header h1 { margin-bottom: 0.25rem; }
    .subtitle { color: #666; }
    .cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1.5rem; }
    .card { background: #fff; border: 1px solid #ddd; border-radius: 8px; padding: 1.5rem; }
    .card h2 { margin: 0 0 0.5rem; font-size: 1.25rem; }
    .card p { color: #555; font-size: 0.9rem; margin-bottom: 0.5rem; }
.paths { display: flex; flex-direction: column; gap: 0.5rem; margin-top: 1rem; }
    .path-btn { padding: 10px 16px; border: 1px solid #0066cc; background: #fff; color: #0066cc; border-radius: 6px; cursor: pointer; font-size: 0.9rem; text-align: left; transition: all 0.2s; }
    .path-btn:hover { background: #0066cc; color: #fff; }
    .actions { text-align: center; margin-top: 2rem; }
    .secondary-btn { padding: 10px 24px; border: 1px solid #666; background: #fff; color: #333; border-radius: 6px; cursor: pointer; font-size: 0.95rem; }
    .secondary-btn:hover { background: #f5f5f5; }
  `]
})
export class DashboardComponent {
  identityTypes: IdentityTypeCard[] = [
    {
      typeId: 14,
      name: 'Amazon Advertising',
      description: 'Create identities for Amazon Advertising API access.',
      paths: [
        { id: 1, label: 'Openbridge OAuth', route: '/path1' },
      ]
    },
    {
      typeId: 17,
      name: 'Amazon Selling Partner',
      description: 'Create identities for Amazon SP-API (Seller Central).',
      paths: [
        { id: 1, label: 'Openbridge OAuth', route: '/path1' },
        { id: 2, label: 'Bring Your Own App', route: '/path2' },
        { id: 3, label: 'Private App', route: '/path3' },
      ]
    },
    {
      typeId: 18,
      name: 'Amazon Vendor Central',
      description: 'Create identities for Amazon Vendor Central API access.',
      paths: [
        { id: 1, label: 'Openbridge OAuth', route: '/path1' },
        { id: 2, label: 'Bring Your Own App', route: '/path2' },
        { id: 3, label: 'Private App', route: '/path3' },
      ]
    }
  ];

  constructor(public router: Router) {}

  navigate(route: string, typeId: number) {
    this.router.navigate([route], { queryParams: { type: typeId } });
  }
}
