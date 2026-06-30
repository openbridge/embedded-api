import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { ApiService } from '../../services/api.service';
import { RegionService, RegionOption } from '../../services/region.service';

@Component({
  selector: 'app-path3-private',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="form-page">
      <button class="back-btn" (click)="router.navigate(['/'])">Back</button>
      <h2>Private App</h2>
      <p class="desc">Register credentials directly — no browser redirect needed.<br>
        Identity Type: <strong>{{ typeName }}</strong></p>

      <!-- Credentials -->
      <div class="step" [class.done]="validated">
        <h3>Step 1: Enter & Validate Credentials</h3>

        <div class="form-group">
          <label>Identity Name</label>
          <input [(ngModel)]="identityName" placeholder="My US Seller Account" />
        </div>

        <div class="form-group">
          <label>Client ID</label>
          <input [(ngModel)]="clientId" placeholder="amzn1.application-oa2-client.abc123" />
        </div>

        <div class="form-group">
          <label>Client Secret</label>
          <input [(ngModel)]="clientSecret" type="password" />
        </div>

        <div class="form-group">
          <label>Refresh Token</label>
          <input [(ngModel)]="refreshToken" placeholder="Atzr|IwEB..." />
        </div>

        <div class="form-group">
          <label>Country</label>
          <select [(ngModel)]="selectedCountry" (ngModelChange)="onCountryChange()">
            <option value="">Select...</option>
            <option *ngFor="let r of countries" [value]="r.code">{{ r.name }} ({{ r.code }})</option>
          </select>
        </div>

        <div class="form-group" *ngIf="typeId === 18">
          <label>Vendor Group ID <span class="hint">(optional — auto-generated if blank)</span></label>
          <input [(ngModel)]="vendorGroupId" placeholder="1234567890" />
        </div>

        <button class="primary-btn" (click)="validate()"
                [disabled]="validating || !clientId || !clientSecret || !refreshToken || !selectedCountry">
          {{ validating ? 'Validating...' : 'Validate Credentials' }}
        </button>

        <div class="result" *ngIf="validated">
          <strong>Credentials valid!</strong>
          <span *ngIf="sellingPartnerId"> Selling Partner ID: {{ sellingPartnerId }}</span>
        </div>
      </div>

      <!-- Step 2 + 3: Encrypt & Create -->
      <div class="step" *ngIf="validated" [class.done]="created">
        <h3>Step 2 & 3: Encrypt & Create Identity</h3>
        <button class="primary-btn" (click)="encryptAndCreate()" [disabled]="creating">
          {{ creating ? 'Creating identity...' : 'Create Remote Identity' }}
        </button>

        <div class="result" *ngIf="created">
          <strong>Identity created!</strong>
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
    .form-group .hint { font-weight: 400; color: #888; font-size: 0.85rem; }
    .form-group input, .form-group select { width: 100%; padding: 8px 12px; border: 1px solid #ccc; border-radius: 4px; font-size: 0.95rem; box-sizing: border-box; }
    .primary-btn { padding: 10px 24px; background: #0066cc; color: #fff; border: none; border-radius: 6px; cursor: pointer; font-size: 0.95rem; }
    .primary-btn:disabled { opacity: 0.5; cursor: not-allowed; }
    .result { margin-top: 1rem; padding: 1rem; background: #d4edda; border-radius: 6px; }
    .result pre { background: #fff; padding: 0.5rem; border-radius: 4px; overflow-x: auto; font-size: 0.8rem; }
    .error { margin-top: 1rem; padding: 1rem; background: #f8d7da; color: #721c24; border-radius: 6px; white-space: pre-wrap; }
  `]
})
export class Path3PrivateComponent implements OnInit {
  typeId = 17;
  typeName = 'Amazon Selling Partner';
  countries: RegionOption[] = [];

  identityName = '';
  clientId = '';
  clientSecret = '';
  refreshToken = '';
  selectedCountry = '';
  apiRegion = '';
  vendorGroupId = '';
  sellingPartnerId = '';

  validated = false;
  validating = false;
  created = false;
  creating = false;
  createResponse: any = null;
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
      this.countries = this.regionService.sellerVendorCountries;
    });
  }

  onCountryChange() {
    this.apiRegion = this.regionService.getApiRegion(this.selectedCountry);
  }

  validate() {
    this.validating = true;
    this.error = '';

    const body = {
      client_id: this.clientId,
      client_secret: this.clientSecret,
      region: this.apiRegion,
      refresh_token: this.refreshToken,
    };

    const obs = this.typeId === 17
      ? this.api.validateSellerCredentials(body)
      : this.api.validateVendorCredentials(body);

    obs.subscribe({
      next: (res) => {
        this.validated = true;
        this.validating = false;
        if (this.typeId === 17 && res?.[0]?.attributes?.selling_partner_id) {
          this.sellingPartnerId = res[0].attributes.selling_partner_id;
        }
      },
      error: (err) => {
        this.error = JSON.stringify(err.error || err.message, null, 2);
        this.validating = false;
      }
    });
  }

  encryptAndCreate() {
    this.creating = true;
    this.error = '';

    this.api.encryptCredentials({
      clientSecret: this.clientSecret,
      refreshToken: this.refreshToken,
    }).subscribe({
      next: (encRes) => {
        const enc = encRes.data.attributes;
        this.createIdentity(enc.clientSecret, enc.refreshToken);
      },
      error: (err) => {
        this.error = JSON.stringify(err.error || err.message, null, 2);
        this.creating = false;
      }
    });
  }

  private createIdentity(encSecret: string, encToken: string) {
    const meta: any[] = [
      { remote_identity_type_meta_key: 26, meta_value: this.clientId, meta_format: 'STRING' },
      { remote_identity_type_meta_key: 27, meta_value: encSecret, meta_format: 'ENCRYPTED_STRING' },
      { remote_identity_type_meta_key: 7, meta_value: encToken, meta_format: 'ENCRYPTED_STRING' },
      { remote_identity_type_meta_key: 31, meta_value: this.apiRegion, meta_format: 'STRING' },
      { remote_identity_type_meta_key: 67, meta_value: 'true', meta_format: 'STRING' },
    ];

    if (this.typeId === 17) {
      meta.push({ remote_identity_type_meta_key: 32, meta_value: this.sellingPartnerId, meta_format: 'STRING' });
    } else {
      meta.push({ remote_identity_type_meta_key: 30, meta_value: this.selectedCountry, meta_format: 'STRING' });
      const vgId = this.vendorGroupId || Math.floor(1000000000 + Math.random() * 9000000000).toString();
      meta.push({ remote_identity_type_meta_key: 32, meta_value: vgId, meta_format: 'STRING' });
    }

    this.api.createRemoteIdentity({
      remote_identity_type: this.typeId,
      name: this.identityName || `${this.typeName} - ${this.selectedCountry}`,
      region: this.selectedCountry,
      remote_unique_id: this.clientId,
      remote_identity_meta_attributes: meta,
    }).subscribe({
      next: (res) => {
        this.createResponse = res;
        this.created = true;
        this.creating = false;
      },
      error: (err) => {
        this.error = JSON.stringify(err.error || err.message, null, 2);
        this.creating = false;
      }
    });
  }
}
