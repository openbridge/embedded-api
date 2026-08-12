import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';

@Component({
  selector: 'app-result',
  imports: [RouterLink],
  templateUrl: './result.component.html',
  styleUrl: './result.component.scss',
})
export class ResultComponent implements OnInit {
  success = false;
  error = '';
  service = '';
  region = '';
  marketplace = '';
  sellingPartnerId = '';
  expiresIn = 0;

  constructor(private route: ActivatedRoute) {}

  ngOnInit() {
    const params = this.route.snapshot.queryParamMap;
    this.success = params.get('success') === 'true';
    this.error = params.get('error') || '';
    this.service = params.get('service') || '';
    this.region = params.get('region') || '';
    this.marketplace = params.get('marketplace') || '';
    this.sellingPartnerId = params.get('selling_partner_id') || '';
    this.expiresIn = Number(params.get('expires_in') || 0);
  }
}
