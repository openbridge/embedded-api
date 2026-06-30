import { Injectable } from '@angular/core';

export interface RegionOption {
  code: string;
  name: string;
}

@Injectable({ providedIn: 'root' })
export class RegionService {
  readonly advertisingRegions: RegionOption[] = [
    { code: 'na', name: 'North America' },
    { code: 'eu', name: 'Europe' },
    { code: 'fe', name: 'Far East' },
  ];

  readonly sellerVendorCountries: RegionOption[] = [
    { code: 'AU', name: 'Australia' },
    { code: 'BE', name: 'Belgium' },
    { code: 'BR', name: 'Brazil' },
    { code: 'CA', name: 'Canada' },
    { code: 'EG', name: 'Egypt' },
    { code: 'FR', name: 'France' },
    { code: 'DE', name: 'Germany' },
    { code: 'IN', name: 'India' },
    { code: 'IE', name: 'Ireland' },
    { code: 'IT', name: 'Italy' },
    { code: 'JP', name: 'Japan' },
    { code: 'MX', name: 'Mexico' },
    { code: 'NL', name: 'Netherlands' },
    { code: 'PL', name: 'Poland' },
    { code: 'SA', name: 'Saudi Arabia' },
    { code: 'SG', name: 'Singapore' },
    { code: 'ES', name: 'Spain' },
    { code: 'SE', name: 'Sweden' },
    { code: 'TR', name: 'Turkey' },
    { code: 'UK', name: 'United Kingdom' },
    { code: 'AE', name: 'United Arab Emirates' },
    { code: 'US', name: 'United States' },
  ];

  private countryToApiRegion: Record<string, string> = {
    US: 'na', CA: 'na', MX: 'na', BR: 'na',
    UK: 'eu', FR: 'eu', DE: 'eu', IT: 'eu', ES: 'eu', NL: 'eu',
    SE: 'eu', PL: 'eu', BE: 'eu', IE: 'eu', EG: 'eu', TR: 'eu',
    SA: 'eu', AE: 'eu', IN: 'eu',
    JP: 'fe', AU: 'fe', SG: 'fe',
  };

  getApiRegion(countryCode: string): string {
    return this.countryToApiRegion[countryCode] || 'na';
  }

  getRegionsForType(typeId: number): RegionOption[] {
    return typeId === 14 ? this.advertisingRegions : this.sellerVendorCountries;
  }
}
