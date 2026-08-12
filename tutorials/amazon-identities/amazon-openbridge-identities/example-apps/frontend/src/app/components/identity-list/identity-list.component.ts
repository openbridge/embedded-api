import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { ApiService } from '../../services/api.service';

@Component({
  selector: 'app-identity-list',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="list-page">
      <button class="back-btn" (click)="router.navigate(['/'])">Back</button>
      <h2>Existing Identities</h2>

      <div class="filters">
        <select [(ngModel)]="filterType" (ngModelChange)="load()">
          <option [ngValue]="null">All Types</option>
          <option [ngValue]="14">Amazon Advertising</option>
          <option [ngValue]="17">Selling Partner</option>
          <option [ngValue]="18">Vendor Central</option>
        </select>
        <label class="checkbox-label">
          <input type="checkbox" [(ngModel)]="showInvalid" (ngModelChange)="load()" />
          Invalid only
        </label>
        <button class="secondary-btn" (click)="load()">Refresh</button>
      </div>

      <div *ngIf="loading" class="loading">Loading...</div>

      <div *ngIf="!loading && identities.length === 0" class="empty">No identities found.</div>

      <table *ngIf="!loading && identities.length > 0">
        <thead>
          <tr>
            <th>ID</th>
            <th>Name</th>
            <th>Type</th>
            <th>Region</th>
            <th>Private App</th>
            <th>Invalid</th>
            <th>Created</th>
          </tr>
        </thead>
        <tbody>
          <tr *ngFor="let id of identities" [class.invalid]="id.attributes?.invalid_identity === 1">
            <td>{{ id.id }}</td>
            <td>{{ id.attributes?.name }}</td>
            <td>{{ getTypeName(id.relationships?.remote_identity_type?.data?.id) }}</td>
            <td>{{ id.attributes?.region }}</td>
            <td>{{ id.attributes?.is_private_app ? 'Yes' : 'No' }}</td>
            <td>{{ id.attributes?.invalid_identity ? 'Yes' : 'No' }}</td>
            <td>{{ id.attributes?.created_at }}</td>
          </tr>
        </tbody>
      </table>

      <div class="error" *ngIf="error">{{ error }}</div>
    </div>
  `,
  styles: [`
    .list-page { max-width: 900px; margin: 0 auto; padding: 2rem; }
    .back-btn { background: none; border: none; color: #0066cc; cursor: pointer; font-size: 0.9rem; padding: 0; margin-bottom: 1rem; }
    .filters { display: flex; gap: 1rem; align-items: center; margin-bottom: 1.5rem; }
    .filters select { padding: 6px 10px; border: 1px solid #ccc; border-radius: 4px; }
    .checkbox-label { display: flex; align-items: center; gap: 4px; font-size: 0.9rem; }
    .secondary-btn { padding: 6px 16px; border: 1px solid #666; background: #fff; color: #333; border-radius: 4px; cursor: pointer; }
    .loading, .empty { text-align: center; padding: 2rem; color: #666; }
    table { width: 100%; border-collapse: collapse; }
    th, td { text-align: left; padding: 8px 12px; border-bottom: 1px solid #e0e0e0; font-size: 0.9rem; }
    th { background: #f5f5f5; font-weight: 600; }
    tr.invalid { background: #fff3cd; }
    .error { margin-top: 1rem; padding: 1rem; background: #f8d7da; color: #721c24; border-radius: 6px; }
  `]
})
export class IdentityListComponent implements OnInit {
  identities: any[] = [];
  filterType: number | null = null;
  showInvalid = false;
  loading = false;
  error = '';

  private typeNames: Record<string, string> = {
    '14': 'Advertising',
    '17': 'Seller',
    '18': 'Vendor',
  };

  constructor(private api: ApiService, public router: Router) {}

  ngOnInit() { this.load(); }

  load() {
    this.loading = true;
    this.error = '';
    const filters: any = {};
    if (this.filterType) filters.remote_identity_type = this.filterType;
    if (this.showInvalid) filters.invalid_identity = 1;

    this.api.listIdentities(filters).subscribe({
      next: (res) => {
        this.identities = Array.isArray(res.data) ? res.data : [res.data].filter(Boolean);
        this.loading = false;
      },
      error: (err) => {
        this.error = JSON.stringify(err.error || err.message, null, 2);
        this.loading = false;
      }
    });
  }

  getTypeName(typeId: string): string {
    return this.typeNames[typeId] || typeId;
  }
}
