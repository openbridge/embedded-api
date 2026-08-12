import { Routes } from '@angular/router';
import { DashboardComponent } from './components/dashboard/dashboard.component';
import { Path1OauthComponent } from './components/path1-oauth/path1-oauth.component';
import { Path2ByoaComponent } from './components/path2-byoa/path2-byoa.component';
import { Path3PrivateComponent } from './components/path3-private/path3-private.component';
import { OauthCallbackComponent } from './components/oauth-callback/oauth-callback.component';
import { IdentityListComponent } from './components/identity-list/identity-list.component';

export const routes: Routes = [
  { path: '', component: DashboardComponent },
  { path: 'path1', component: Path1OauthComponent },
  { path: 'path2', component: Path2ByoaComponent },
  { path: 'path3', component: Path3PrivateComponent },
  { path: 'oauth-callback', component: OauthCallbackComponent },
  { path: 'identities', component: IdentityListComponent },
  { path: '**', redirectTo: '' },
];
