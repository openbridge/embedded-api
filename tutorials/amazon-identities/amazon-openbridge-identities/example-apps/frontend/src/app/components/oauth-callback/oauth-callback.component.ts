import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';

@Component({
  selector: 'app-oauth-callback',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="callback-page">
      <div *ngIf="!isError" class="success">
        <h2>Authorization Successful</h2>
        <p>Remote Identity ID: <strong>{{ riId }}</strong></p>
        <p>Reauth: {{ reauth }}</p>
        <p>State: {{ state }}</p>
        <button class="primary-btn" (click)="router.navigate(['/identities'])">View Identities</button>
        <button class="secondary-btn" (click)="router.navigate(['/'])">Back to Dashboard</button>
      </div>

      <div *ngIf="isError" class="error-box">
        <h2>Authorization Failed</h2>
        <p><strong>Error:</strong> {{ statusType }}</p>
        <p>{{ statusMessage }}</p>
        <button class="secondary-btn" (click)="router.navigate(['/'])">Back to Dashboard</button>
      </div>
    </div>
  `,
  styles: [`
    .callback-page { max-width: 500px; margin: 4rem auto; padding: 2rem; text-align: center; }
    .success { padding: 2rem; background: #d4edda; border-radius: 8px; }
    .error-box { padding: 2rem; background: #f8d7da; border-radius: 8px; color: #721c24; }
    .primary-btn { padding: 10px 24px; background: #0066cc; color: #fff; border: none; border-radius: 6px; cursor: pointer; margin: 0.5rem; }
    .secondary-btn { padding: 10px 24px; background: #fff; border: 1px solid #666; color: #333; border-radius: 6px; cursor: pointer; margin: 0.5rem; }
  `]
})
export class OauthCallbackComponent implements OnInit {
  state = '';
  riId = '';
  reauth = '';
  isError = false;
  statusType = '';
  statusMessage = '';

  constructor(private route: ActivatedRoute, public router: Router) {}

  ngOnInit() {
    this.route.queryParams.subscribe(params => {
      this.state = params['state'] || '';
      this.riId = params['ri_id'] || '';
      this.reauth = params['reauth'] || '';
      this.isError = params['status'] === 'error';
      this.statusType = params['status_type'] || '';
      this.statusMessage = params['status_message'] || '';
    });
  }
}
