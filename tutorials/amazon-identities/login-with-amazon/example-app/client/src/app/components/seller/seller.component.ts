import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-seller',
  imports: [FormsModule],
  templateUrl: './seller.component.html',
  styleUrl: './seller.component.scss',
})
export class SellerComponent {
  activeTab: 'public' | 'private' = 'public';

  // Public app
  selectedMarketplace = 'US';

  // Private app form
  privateClientId = '';
  privateClientSecret = '';
  privateRefreshToken = '';
  privateRegion = 'NA';
  privateResult: { success?: boolean; error?: string; expires_in?: number } | null = null;

  marketplaces = [
    { code: 'US', label: 'United States', region: 'NA' },
    { code: 'CA', label: 'Canada', region: 'NA' },
    { code: 'MX', label: 'Mexico', region: 'NA' },
    { code: 'BR', label: 'Brazil', region: 'NA' },
    { code: 'UK', label: 'United Kingdom', region: 'EU' },
    { code: 'DE', label: 'Germany', region: 'EU' },
    { code: 'FR', label: 'France', region: 'EU' },
    { code: 'IT', label: 'Italy', region: 'EU' },
    { code: 'ES', label: 'Spain', region: 'EU' },
    { code: 'NL', label: 'Netherlands', region: 'EU' },
    { code: 'SE', label: 'Sweden', region: 'EU' },
    { code: 'PL', label: 'Poland', region: 'EU' },
    { code: 'BE', label: 'Belgium', region: 'EU' },
    { code: 'EG', label: 'Egypt', region: 'EU' },
    { code: 'TR', label: 'Turkey', region: 'EU' },
    { code: 'SA', label: 'Saudi Arabia', region: 'EU' },
    { code: 'AE', label: 'U.A.E.', region: 'EU' },
    { code: 'IN', label: 'India', region: 'EU' },
    { code: 'SG', label: 'Singapore', region: 'FE' },
    { code: 'AU', label: 'Australia', region: 'FE' },
    { code: 'JP', label: 'Japan', region: 'FE' },
  ];

  regions = [
    { code: 'NA', label: 'North America' },
    { code: 'EU', label: 'Europe' },
    { code: 'FE', label: 'Far East' },
  ];

  constructor(private authService: AuthService) {}

  startPublicAuth() {
    this.authService.initiateSellerAuth(this.selectedMarketplace).subscribe({
      next: (res) => {
        window.location.href = res.url;
      },
      error: (err) => {
        alert('Failed to initiate auth: ' + (err.error?.error || err.message));
      },
    });
  }

  submitPrivateAuth() {
    this.privateResult = null;
    this.authService.authenticateSellerPrivate({
      client_id: this.privateClientId,
      client_secret: this.privateClientSecret,
      refresh_token: this.privateRefreshToken,
      region: this.privateRegion,
    }).subscribe({
      next: (res) => {
        this.privateResult = { success: true, expires_in: res.expires_in };
      },
      error: (err) => {
        this.privateResult = { success: false, error: err.error?.error || err.message };
      },
    });
  }
}
