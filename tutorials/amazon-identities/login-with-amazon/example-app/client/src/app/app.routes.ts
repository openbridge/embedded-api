import { Routes } from '@angular/router';
import { HomeComponent } from './components/home/home.component';
import { AdvertisingComponent } from './components/advertising/advertising.component';
import { SellerComponent } from './components/seller/seller.component';
import { VendorComponent } from './components/vendor/vendor.component';
import { ResultComponent } from './components/result/result.component';

export const routes: Routes = [
  { path: '', component: HomeComponent },
  { path: 'advertising', component: AdvertisingComponent },
  { path: 'seller', component: SellerComponent },
  { path: 'vendor', component: VendorComponent },
  { path: 'result', component: ResultComponent },
  { path: '**', redirectTo: '' },
];
