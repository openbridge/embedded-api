import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { ApiService } from '../../services/api.service';
import { RegionService, RegionOption } from '../../services/region.service';
import { environment } from '../../../environments/environment';

@Component({
  selector: 'app-path1-oauth',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="form-page">
      <button class="back-btn" (click)="router.navigate(['/'])">Back</button>
      <h2>Openbridge OAuth</h2>
      <p class="desc">Standard OAuth redirect using Openbridge's built-in application.<br>
        Identity Type: <strong>{{ typeName }}</strong></p>

      <div class="form-group">
        <label>{{ typeId === 14 ? 'Region' : 'Country' }}</label>
        <select [(ngModel)]="selectedRegion">
          <option value="">Select...</option>
          <option *ngFor="let r of regions" [value]="r.code">{{ r.name }} ({{ r.code }})</option>
        </select>
      </div>

      <button class="primary-btn" (click)="startOAuth()" [disabled]="loading || !selectedRegion">
        {{ loading ? 'Creating state...' : 'Start OAuth Flow' }}
      </button>

      <div class="result" *ngIf="stateToken">
        <p>Redirecting to Amazon authorization...</p>
        <a [href]="oauthUrl" target="_blank" class="primary-btn" style="display: inline-block; text-decoration: none; margin-top: 0.5rem;">
          Open Authorization Page
        </a>
      </div>

      <div class="error" *ngIf="error">{{ error }}</div>
    </div>
  `,
  styles: [`
    .form-page { max-width: 600px; margin: 0 auto; padding: 2rem; }
    .back-btn { background: none; border: none; color: #0066cc; cursor: pointer; font-size: 0.9rem; padding: 0; margin-bottom: 1rem; }
    .desc { color: #555; margin-bottom: 1.5rem; }
    .form-group { margin-bottom: 1rem; }
    .form-group label { display: block; font-weight: 600; margin-bottom: 4px; }
    .form-group input, .form-group select { width: 100%; padding: 8px 12px; border: 1px solid #ccc; border-radius: 4px; font-size: 0.95rem; box-sizing: border-box; }
    .primary-btn { padding: 10px 24px; background: #0066cc; color: #fff; border: none; border-radius: 6px; cursor: pointer; font-size: 0.95rem; }
    .primary-btn:disabled { opacity: 0.5; cursor: not-allowed; }
    .result { margin-top: 1.5rem; padding: 1rem; background: #d4edda; border-radius: 6px; }
    .result pre { background: #fff; padding: 0.5rem; border-radius: 4px; overflow-x: auto; font-size: 0.8rem; }
    .error { margin-top: 1rem; padding: 1rem; background: #f8d7da; color: #721c24; border-radius: 6px; }
  `]
})
export class Path1OauthComponent implements OnInit {
  typeId = 14;
  typeName = 'Amazon Advertising';
  regions: RegionOption[] = [];
  selectedRegion = '';
  returnUrl = '';
  loading = false;
  stateToken = '';
  stateResponse: any = null;
  oauthUrl = '';
  error = '';

  private typeNames: Record<number, string> = {
    14: 'Amazon Advertising',
    17: 'Amazon Selling Partner',
    18: 'Amazon Vendor Central',
  };

  constructor(
    private route: ActivatedRoute,
    public router: Router,
    private api: ApiService,
    private regionService: RegionService
  ) {}

  ngOnInit() {
    this.route.queryParams.subscribe(params => {
      this.typeId = parseInt(params['type']) || 14;
      this.typeName = this.typeNames[this.typeId] || 'Unknown';
      this.regions = this.regionService.getRegionsForType(this.typeId);
    });
    this.returnUrl = environment.oauthCallbackUrl;
  }

  startOAuth() {
    this.loading = true;
    this.error = '';
    this.api.createState({
      remote_identity_type_id: this.typeId,
      region: this.selectedRegion,
      return_url: this.returnUrl,
    }).subscribe({
      next: (res) => {
        this.stateResponse = res;
        this.stateToken = res.data.attributes.token;
        this.oauthUrl = `${environment.oauthInitializeUrl}?state=${this.stateToken}`;
        this.loading = false;
      },
      error: (err) => {
        this.error = JSON.stringify(err.error || err.message, null, 2);
        this.loading = false;
      }
    });
  }
}
