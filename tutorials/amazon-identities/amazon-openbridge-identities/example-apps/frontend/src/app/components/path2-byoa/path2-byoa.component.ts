import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { ApiService } from '../../services/api.service';
import { RegionService, RegionOption } from '../../services/region.service';
import { environment } from '../../../environments/environment';

@Component({
  selector: 'app-path2-byoa',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="form-page">
      <button class="back-btn" (click)="router.navigate(['/'])">Back</button>
      <h2>Bring Your Own App</h2>
      <p class="desc">Use your own SP-API OAuth credentials.<br>
        Identity Type: <strong>{{ typeName }}</strong></p>

      <!-- Step 1: Register OAuth App -->
      <div class="step" [class.done]="oauthId">
        <h3>Step 1: Register OAuth App</h3>

        <div class="form-group">
          <label>Client ID</label>
          <input [(ngModel)]="clientId" placeholder="amzn1.application-oa2-client.abc123" />
        </div>

        <div class="form-group">
          <label>Client Secret</label>
          <input [(ngModel)]="clientSecret" type="password" />
        </div>

        <div class="form-group">
          <label>SP-API App ID</label>
          <input [(ngModel)]="appId" placeholder="amzn1.sp.solution.abc123" />
        </div>

        <button class="primary-btn" (click)="registerApp()" [disabled]="loading || !clientId || !clientSecret || !appId">
          {{ loading ? 'Registering...' : 'Register OAuth App' }}
        </button>

        <div class="result" *ngIf="oauthId">
          <strong>OAuth App registered.</strong>
        </div>
      </div>

      <!-- Step 2: Create state + redirect -->
      <div class="step" *ngIf="oauthId">
        <h3>Step 2: Create State & Redirect</h3>

        <div class="form-group">
          <label>Country</label>
          <select [(ngModel)]="selectedRegion">
            <option value="">Select...</option>
            <option *ngFor="let r of regions" [value]="r.code">{{ r.name }} ({{ r.code }})</option>
          </select>
        </div>

        <button class="primary-btn" (click)="startOAuth()" [disabled]="loadingState || !selectedRegion">
          {{ loadingState ? 'Creating state...' : 'Start OAuth Flow' }}
        </button>

        <div class="result" *ngIf="stateToken">
          <a [href]="oauthUrl" target="_blank" class="primary-btn" style="display: inline-block; text-decoration: none; margin-top: 0.5rem;">
            Open Authorization Page
          </a>
        </div>
      </div>

      <div class="error" *ngIf="error">{{ error }}</div>
    </div>
  `,
  styles: [`
    .form-page { max-width: 600px; margin: 0 auto; padding: 2rem; }
    .back-btn { background: none; border: none; color: #0066cc; cursor: pointer; font-size: 0.9rem; padding: 0; margin-bottom: 1rem; }
    .desc { color: #555; margin-bottom: 1.5rem; }
    .step { margin-bottom: 2rem; padding: 1rem; border: 1px solid #e0e0e0; border-radius: 8px; }
    .step.done { border-color: #28a745; }
    .step h3 { margin-top: 0; }
    .form-group { margin-bottom: 1rem; }
    .form-group label { display: block; font-weight: 600; margin-bottom: 4px; }
    .form-group input, .form-group select { width: 100%; padding: 8px 12px; border: 1px solid #ccc; border-radius: 4px; font-size: 0.95rem; box-sizing: border-box; }
    .primary-btn { padding: 10px 24px; background: #0066cc; color: #fff; border: none; border-radius: 6px; cursor: pointer; font-size: 0.95rem; }
    .primary-btn:disabled { opacity: 0.5; cursor: not-allowed; }
    .result { margin-top: 1rem; padding: 1rem; background: #d4edda; border-radius: 6px; }
    .result pre { background: #fff; padding: 0.5rem; border-radius: 4px; overflow-x: auto; font-size: 0.8rem; }
    .error { margin-top: 1rem; padding: 1rem; background: #f8d7da; color: #721c24; border-radius: 6px; white-space: pre-wrap; }
  `]
})
export class Path2ByoaComponent implements OnInit {
  typeId = 17;
  typeName = 'Amazon Selling Partner';
  regions: RegionOption[] = [];

  clientId = '';
  clientSecret = '';
  appId = '';
  oauthId: number | null = null;
  registerResponse: any = null;

  selectedRegion = '';
  returnUrl = '';
  stateToken = '';
  stateResponse: any = null;
  oauthUrl = '';

  loading = false;
  loadingState = false;
  error = '';

  private typeNames: Record<number, string> = {
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
      this.typeId = parseInt(params['type']) || 17;
      if (this.typeId === 14) { this.router.navigate(['/path1'], { queryParams: { type: 14 } }); return; }
      this.typeName = this.typeNames[this.typeId] || 'Unknown';
      this.regions = this.regionService.getRegionsForType(this.typeId);
    });
    this.returnUrl = environment.oauthCallbackUrl;
  }

  registerApp() {
    this.loading = true;
    this.error = '';
    this.api.registerOAuthApp({
      remote_identity_type: this.typeId,
      client_id: this.clientId,
      client_secret: this.clientSecret,
      app_id: this.appId,
    }).subscribe({
      next: (res) => {
        this.registerResponse = res;
        this.oauthId = parseInt(res.data.id);
        this.loading = false;
      },
      error: (err) => {
        this.error = JSON.stringify(err.error || err.message, null, 2);
        this.loading = false;
      }
    });
  }

  startOAuth() {
    this.loadingState = true;
    this.error = '';
    this.api.createState({
      remote_identity_type_id: this.typeId,
      region: this.selectedRegion,
      return_url: this.returnUrl,
      oauth_id: this.oauthId,
    }).subscribe({
      next: (res) => {
        this.stateResponse = res;
        this.stateToken = res.data.attributes.token;
        this.oauthUrl = `${environment.oauthInitializeUrl}?state=${this.stateToken}`;
        this.loadingState = false;
      },
      error: (err) => {
        this.error = JSON.stringify(err.error || err.message, null, 2);
        this.loadingState = false;
      }
    });
  }
}
