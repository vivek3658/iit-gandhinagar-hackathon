import type {
  CitizenProviderLinks,
  LinkProvidersBody,
  ProviderCategory,
  UtilityProvider,
} from './providers.schema';
import type { Pool } from 'pg';

export interface CitizenLinkRecord {
  userId: string;
  electricityProviderId: string | null;
  gasProviderId: string | null;
  waterProviderId: string | null;
  transitProviderIds: string[];
  consumerNumbers: Record<string, string>;
  linkedAt: string;
}

export class ProvidersService {
  private static schemaReady = new WeakMap<Pool, Promise<void>>();
  // Master Directory of Gujarat Utility Providers
  private static providers: UtilityProvider[] = [
    // --- 1. Electricity DISCOMs ---
    {
      id: 'torrent_power',
      name: 'Torrent Power Ltd',
      category: 'ELECTRICITY',
      districts: ['Ahmedabad', 'Gandhinagar', 'Surat'],
      code: 'TORRENT',
      contactPhone: '19124',
      peakHours: '18:30 - 21:30',
      activeAlertCount: 1,
    },
    {
      id: 'ugvcl',
      name: 'Uttar Gujarat Vij Company Ltd (UGVCL)',
      category: 'ELECTRICITY',
      districts: ['Mehsana', 'Patan', 'Banaskantha', 'Sabarkantha', 'Gandhinagar', 'Ahmedabad'],
      code: 'UGVCL',
      contactPhone: '19122',
      peakHours: '19:00 - 22:00',
      activeAlertCount: 0,
    },
    {
      id: 'dgvcl',
      name: 'Dakshin Gujarat Vij Company Ltd (DGVCL)',
      category: 'ELECTRICITY',
      districts: ['Surat', 'Navsari', 'Valsad', 'Tapi', 'Bharuch', 'Dang'],
      code: 'DGVCL',
      contactPhone: '19123',
      peakHours: '18:30 - 21:30',
      activeAlertCount: 0,
    },
    {
      id: 'mgvcl',
      name: 'Madhya Gujarat Vij Company Ltd (MGVCL)',
      category: 'ELECTRICITY',
      districts: ['Vadodara', 'Anand', 'Kheda', 'Panchmahal', 'Dahod', 'Mahisagar', 'Chhotaudepur'],
      code: 'MGVCL',
      contactPhone: '19124',
      peakHours: '19:00 - 22:00',
      activeAlertCount: 0,
    },
    {
      id: 'pgvcl',
      name: 'Paschim Gujarat Vij Company Ltd (PGVCL)',
      category: 'ELECTRICITY',
      districts: [
        'Rajkot',
        'Jamnagar',
        'Bhavnagar',
        'Junagadh',
        'Amreli',
        'Porbandar',
        'Kutch',
        'Surendranagar',
        'Morbi',
      ],
      code: 'PGVCL',
      contactPhone: '19122',
      peakHours: '18:00 - 21:30',
      activeAlertCount: 0,
    },

    // --- 2. Cooking Gas Providers (LPG & PNG) ---
    {
      id: 'adani_png',
      name: 'Adani Total Gas Ltd (Piped PNG & CNG)',
      category: 'GAS',
      districts: ['Ahmedabad', 'Vadodara', 'Surat', 'Navsari', 'Kheda', 'Surendranagar'],
      code: 'ADANIGAS',
      contactPhone: '1800-233-3555',
      activeAlertCount: 0,
    },
    {
      id: 'gujarat_gas',
      name: 'Gujarat Gas Ltd (GGL Piped Natural Gas)',
      category: 'GAS',
      districts: [
        'Surat',
        'Bharuch',
        'Ankleshwar',
        'Valsad',
        'Navsari',
        'Rajkot',
        'Bhavnagar',
        'Jamnagar',
      ],
      code: 'GUJGAS',
      contactPhone: '1800-103-5001',
      activeAlertCount: 0,
    },
    {
      id: 'indane_lpg',
      name: 'Indane LPG (Indian Oil Corporation Ltd)',
      category: 'GAS',
      districts: [
        'Ahmedabad',
        'Surat',
        'Vadodara',
        'Rajkot',
        'Gandhinagar',
        'Bhavnagar',
        'Jamnagar',
        'Junagadh',
        'Kutch',
      ],
      code: 'INDANE',
      contactPhone: '1906',
      activeAlertCount: 0,
    },
    {
      id: 'bharat_gas',
      name: 'Bharat Gas (Bharat Petroleum BPCL)',
      category: 'GAS',
      districts: ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar', 'Gandhinagar'],
      code: 'BPCL_GAS',
      contactPhone: '1906',
      activeAlertCount: 0,
    },
    {
      id: 'hp_gas',
      name: 'HP Gas (Hindustan Petroleum HPCL)',
      category: 'GAS',
      districts: ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Junagadh'],
      code: 'HPCL_GAS',
      contactPhone: '1906',
      activeAlertCount: 0,
    },

    // --- 3. Municipal Water Boards ---
    {
      id: 'amc_water',
      name: 'Ahmedabad Municipal Corporation (AMC Water Works)',
      category: 'WATER',
      districts: ['Ahmedabad'],
      code: 'AMC_WATER',
      contactPhone: '155303',
      supplyWindow: '06:00 - 08:00 AM (Morning Timed)',
      activeAlertCount: 1,
    },
    {
      id: 'smc_water',
      name: 'Surat Municipal Corporation (SMC Hydraulic Dept)',
      category: 'WATER',
      districts: ['Surat'],
      code: 'SMC_WATER',
      contactPhone: '0261-2423751',
      supplyWindow: '06:30 - 08:30 AM',
      activeAlertCount: 0,
    },
    {
      id: 'vmc_water',
      name: 'Vadodara Municipal Corporation (VMC Water Works)',
      category: 'WATER',
      districts: ['Vadodara'],
      code: 'VMC_WATER',
      contactPhone: '1800-233-0266',
      supplyWindow: '06:00 - 08:00 AM',
      activeAlertCount: 0,
    },
    {
      id: 'rmc_water',
      name: 'Rajkot Municipal Corporation (RMC Water Drainage)',
      category: 'WATER',
      districts: ['Rajkot'],
      code: 'RMC_WATER',
      contactPhone: '0281-2224444',
      supplyWindow: '07:00 - 08:30 AM',
      activeAlertCount: 0,
    },
    {
      id: 'gwssb',
      name: 'Gujarat Water Supply & Sewerage Board (GWSSB)',
      category: 'WATER',
      districts: [
        'Gandhinagar',
        'Mehsana',
        'Patan',
        'Banaskantha',
        'Kutch',
        'Surendranagar',
        'Bhavnagar',
      ],
      code: 'GWSSB',
      contactPhone: '079-23253501',
      supplyWindow: 'Rotational 2-Hour Sump Supply',
      activeAlertCount: 0,
    },

    // --- 4. Public Transit Authorities ---
    {
      id: 'gmrc_metro',
      name: 'GMRC (Gujarat Metro Rail Corporation - Ahmedabad / Surat)',
      category: 'TRANSIT',
      districts: ['Ahmedabad', 'Gandhinagar', 'Surat'],
      code: 'GMRC',
      contactPhone: '079-22960123',
      activeAlertCount: 0,
    },
    {
      id: 'amts_bus',
      name: 'AMTS (Ahmedabad Municipal Transport Service)',
      category: 'TRANSIT',
      districts: ['Ahmedabad'],
      code: 'AMTS',
      contactPhone: '079-25391881',
      activeAlertCount: 0,
    },
    {
      id: 'brts_janmarg',
      name: 'Janmarg BRTS (Ahmedabad Bus Rapid Transit)',
      category: 'TRANSIT',
      districts: ['Ahmedabad'],
      code: 'BRTS',
      contactPhone: '079-25507770',
      activeAlertCount: 0,
    },
    {
      id: 'gsrtc_bus',
      name: 'GSRTC (Gujarat State Road Transport Corporation)',
      category: 'TRANSIT',
      districts: [
        'Ahmedabad',
        'Surat',
        'Vadodara',
        'Rajkot',
        'Gandhinagar',
        'Bhavnagar',
        'Jamnagar',
        'Junagadh',
        'Kutch',
      ],
      code: 'GSRTC',
      contactPhone: '1800-233-6655',
      activeAlertCount: 0,
    },
  ];

  // User link repository
  private static userLinks = new Map<string, CitizenLinkRecord>();

  public static listProviders(category?: ProviderCategory, district?: string): UtilityProvider[] {
    return this.providers
      .filter((p) => {
        if (category && p.category !== category) return false;
        if (district && !p.districts.some((d) => d.toLowerCase() === district.toLowerCase()))
          return false;
        return true;
      })
      .map((provider) => ({ ...provider, activeAlertCount: null }));
  }

  public static getProviderById(id: string): UtilityProvider | null {
    const found = this.providers.find((p) => p.id === id);
    return found ? { ...found } : null;
  }

  public static async getCitizenLinks(
    userId: string,
    db: Pool | null,
    allowTestMemory: boolean,
  ): Promise<CitizenProviderLinks> {
    let record = db ? undefined : this.userLinks.get(userId);
    if (db) {
      await this.ensureSchema(db);
      const result = await db.query(
        `SELECT electricity_provider_id, gas_provider_id, water_provider_id,
                transit_provider_ids, consumer_numbers, linked_at
         FROM citizen_provider_links WHERE user_id = $1`,
        [userId],
      );
      const row = result.rows[0];
      if (row) {
        record = {
          userId,
          electricityProviderId: row.electricity_provider_id,
          gasProviderId: row.gas_provider_id,
          waterProviderId: row.water_provider_id,
          transitProviderIds: row.transit_provider_ids || [],
          consumerNumbers: row.consumer_numbers || {},
          linkedAt: new Date(String(row.linked_at)).toISOString(),
        };
      }
    } else if (!allowTestMemory) {
      throw new Error('PostgreSQL is required for provider-link data.');
    }

    record ??= {
      userId,
      electricityProviderId: null,
      gasProviderId: null,
      waterProviderId: null,
      transitProviderIds: [],
      consumerNumbers: {},
      linkedAt: new Date().toISOString(),
    };

    return this.toCitizenLinks(record);
  }

  private static toCitizenLinks(record: CitizenLinkRecord): CitizenProviderLinks {
    return {
      userId: record.userId,
      electricityProvider: record.electricityProviderId
        ? this.getProviderById(record.electricityProviderId)
        : null,
      gasProvider: record.gasProviderId ? this.getProviderById(record.gasProviderId) : null,
      waterProvider: record.waterProviderId ? this.getProviderById(record.waterProviderId) : null,
      transitProviders: record.transitProviderIds
        .map((id) => this.getProviderById(id))
        .filter((p): p is UtilityProvider => p !== null),
      consumerNumbers: { ...record.consumerNumbers },
      linkedAt: record.linkedAt,
    };
  }

  public static async linkCitizenProviders(
    userId: string,
    body: LinkProvidersBody,
    db: Pool | null,
    allowTestMemory: boolean,
  ): Promise<CitizenProviderLinks> {
    const linked = await this.getCitizenLinks(userId, db, allowTestMemory);
    const existing: CitizenLinkRecord = {
      userId,
      electricityProviderId: linked.electricityProvider?.id ?? null,
      gasProviderId: linked.gasProvider?.id ?? null,
      waterProviderId: linked.waterProvider?.id ?? null,
      transitProviderIds: linked.transitProviders.map((provider) => provider.id),
      consumerNumbers: linked.consumerNumbers,
      linkedAt: linked.linkedAt,
    };
    const updated: CitizenLinkRecord = {
      userId,
      electricityProviderId:
        body.electricityProviderId !== undefined
          ? body.electricityProviderId
          : existing.electricityProviderId,
      gasProviderId: body.gasProviderId !== undefined ? body.gasProviderId : existing.gasProviderId,
      waterProviderId:
        body.waterProviderId !== undefined ? body.waterProviderId : existing.waterProviderId,
      transitProviderIds:
        body.transitProviderIds !== undefined
          ? body.transitProviderIds
          : existing.transitProviderIds,
      consumerNumbers: {
        ...existing.consumerNumbers,
        ...(body.consumerNumbers || {}),
      },
      linkedAt: new Date().toISOString(),
    };

    this.validateProviderCategory(updated.electricityProviderId, 'ELECTRICITY');
    this.validateProviderCategory(updated.gasProviderId, 'GAS');
    this.validateProviderCategory(updated.waterProviderId, 'WATER');
    for (const id of updated.transitProviderIds) {
      this.validateProviderCategory(id, 'TRANSIT');
    }

    if (db) {
      await this.ensureSchema(db);
      await db.query(
        `INSERT INTO citizen_provider_links
           (user_id, electricity_provider_id, gas_provider_id, water_provider_id,
            transit_provider_ids, consumer_numbers, linked_at)
         VALUES ($1, $2, $3, $4, $5::jsonb, $6::jsonb, NOW())
         ON CONFLICT (user_id) DO UPDATE SET
           electricity_provider_id = EXCLUDED.electricity_provider_id,
           gas_provider_id = EXCLUDED.gas_provider_id,
           water_provider_id = EXCLUDED.water_provider_id,
           transit_provider_ids = EXCLUDED.transit_provider_ids,
           consumer_numbers = EXCLUDED.consumer_numbers,
           linked_at = NOW()`,
        [
          userId,
          updated.electricityProviderId,
          updated.gasProviderId,
          updated.waterProviderId,
          JSON.stringify(updated.transitProviderIds),
          JSON.stringify(updated.consumerNumbers),
        ],
      );
    } else if (allowTestMemory) {
      this.userLinks.set(userId, updated);
    } else {
      throw new Error('PostgreSQL is required for provider-link data.');
    }
    return this.toCitizenLinks(updated);
  }

  private static validateProviderCategory(id: string | null, category: ProviderCategory): void {
    if (!id) return;
    const provider = this.getProviderById(id);
    if (!provider || provider.category !== category) {
      throw new Error(`Provider "${id}" is not a valid ${category} provider.`);
    }
  }

  private static async ensureSchema(db: Pool): Promise<void> {
    let ready = this.schemaReady.get(db);
    if (!ready) {
      ready = db
        .query(
          `
          CREATE TABLE IF NOT EXISTS citizen_provider_links (
            user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
            electricity_provider_id TEXT,
            gas_provider_id TEXT,
            water_provider_id TEXT,
            transit_provider_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
            consumer_numbers JSONB NOT NULL DEFAULT '{}'::jsonb,
            linked_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
          )
        `,
        )
        .then(() => undefined)
        .catch((error: unknown) => {
          this.schemaReady.delete(db);
          throw error;
        });
      this.schemaReady.set(db, ready);
    }
    await ready;
  }
}
