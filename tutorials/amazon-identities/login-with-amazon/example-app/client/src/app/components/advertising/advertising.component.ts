import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-advertising',
  imports: [FormsModule],
  templateUrl: './advertising.component.html',
  styleUrl: './advertising.component.scss',
})
export class AdvertisingComponent {
  selectedRegion = 'NA';
  regions = [
    { code: 'NA', label: 'North America', url: 'https://www.amazon.com/ap/oa' },
    { code: 'EU', label: 'Europe', url: 'https://eu.account.amazon.com/ap/oa' },
    { code: 'FE', label: 'Far East', url: 'https://apac.account.amazon.com/ap/oa' },
  ];

  constructor(private authService: AuthService) {}

  startAuth() {
    this.authService.initiateAdvertisingAuth(this.selectedRegion).subscribe({
      next: (res) => {
        window.location.href = res.url;
      },
      error: (err) => {
        alert('Failed to initiate auth: ' + (err.error?.error || err.message));
      },
    });
  }
}
