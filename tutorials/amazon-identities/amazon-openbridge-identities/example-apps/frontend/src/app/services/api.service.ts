import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

@Injectable({ providedIn: 'root' })
export class ApiService {
  private url = environment.apiUrl;

  constructor(private http: HttpClient) {}

  getHealth(): Observable<any> {
    return this.http.get(`${this.url}/health`);
  }

  getConfig(): Observable<any> {
    return this.http.get(`${this.url}/config`);
  }

  createState(body: any): Observable<any> {
    return this.http.post(`${this.url}/state`, body);
  }

  registerOAuthApp(body: any): Observable<any> {
    return this.http.post(`${this.url}/oauth/apps`, body);
  }

  listOAuthApps(remoteIdentityTypeId?: number): Observable<any> {
    const params = remoteIdentityTypeId ? `?remote_identity_type_id=${remoteIdentityTypeId}` : '';
    return this.http.get(`${this.url}/oauth/apps${params}`);
  }

  deleteOAuthApp(id: number): Observable<any> {
    return this.http.delete(`${this.url}/oauth/apps/${id}`);
  }

  validateSellerCredentials(body: any): Observable<any> {
    return this.http.post(`${this.url}/service/sp/sp-id`, body);
  }

  validateVendorCredentials(body: any): Observable<any> {
    return this.http.post(`${this.url}/service/sp/validate-creds`, body);
  }

  encryptCredentials(body: any): Observable<any> {
    return this.http.post(`${this.url}/service/encrypt`, body);
  }

  createRemoteIdentity(body: any): Observable<any> {
    return this.http.post(`${this.url}/ri`, body);
  }

  updateRemoteIdentity(id: number, body: any): Observable<any> {
    return this.http.patch(`${this.url}/ri/${id}`, body);
  }

  listIdentities(filters?: any): Observable<any> {
    const params = new URLSearchParams();
    if (filters?.remote_identity_type) params.set('remote_identity_type', String(filters.remote_identity_type));
    if (filters?.invalid_identity) params.set('invalid_identity', String(filters.invalid_identity));
    const qs = params.toString();
    return this.http.get(`${this.url}/identities${qs ? '?' + qs : ''}`);
  }

  getIdentity(id: number): Observable<any> {
    return this.http.get(`${this.url}/identities/${id}`);
  }

  getIdentityMeta(id: number): Observable<any> {
    return this.http.get(`${this.url}/identities/${id}/meta`);
  }

  reauthorize(body: any): Observable<any> {
    return this.http.post(`${this.url}/reauth`, body);
  }
}
