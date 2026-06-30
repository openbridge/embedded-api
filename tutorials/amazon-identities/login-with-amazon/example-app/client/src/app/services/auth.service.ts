import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface EndpointsData {
  advertisingAuthUrls: Record<string, string>;
  tokenEndpoints: Record<string, string>;
  sellerCentralUrls: Record<string, string>;
  vendorCentralUrls: Record<string, string>;
  marketplaceRegions: Record<string, string>;
}

export interface PrivateAuthRequest {
  client_id: string;
  client_secret: string;
  refresh_token: string;
  region: string;
}

export interface PrivateAuthResponse {
  success: boolean;
  service: string;
  expires_in: number;
  token_type: string;
  error?: string;
}

@Injectable({ providedIn: 'root' })
export class AuthService {
  private apiBase = 'https://localhost:3443';

  constructor(private http: HttpClient) {}

  getEndpoints(): Observable<EndpointsData> {
    return this.http.get<EndpointsData>(`${this.apiBase}/api/endpoints`);
  }

  initiateAdvertisingAuth(region: string): Observable<{ url: string }> {
    return this.http.get<{ url: string }>(
      `${this.apiBase}/auth/advertising/initiate`,
      { params: { region }, withCredentials: true }
    );
  }

  initiateSellerAuth(marketplace: string): Observable<{ url: string }> {
    return this.http.get<{ url: string }>(
      `${this.apiBase}/auth/seller/initiate`,
      { params: { marketplace }, withCredentials: true }
    );
  }

  initiateVendorAuth(marketplace: string): Observable<{ url: string }> {
    return this.http.get<{ url: string }>(
      `${this.apiBase}/auth/vendor/initiate`,
      { params: { marketplace }, withCredentials: true }
    );
  }

  authenticateSellerPrivate(data: PrivateAuthRequest): Observable<PrivateAuthResponse> {
    return this.http.post<PrivateAuthResponse>(
      `${this.apiBase}/auth/seller/private`, data, { withCredentials: true }
    );
  }

  authenticateVendorPrivate(data: PrivateAuthRequest): Observable<PrivateAuthResponse> {
    return this.http.post<PrivateAuthResponse>(
      `${this.apiBase}/auth/vendor/private`, data, { withCredentials: true }
    );
  }
}
