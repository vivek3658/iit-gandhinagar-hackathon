import crypto from 'node:crypto';
import { ActivityService } from '../activity/activity.service';
import type {
  CitizenProviderLinks,
  LinkProvidersBody,
  ProviderBroadcastBody,
  ProviderBroadcastResponse,
  ProviderCategory,
  UtilityProvider,
} from './providers.schema';

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
      districts: ['Rajkot', 'Jamnagar', 'Bhavnagar', 'Junagadh', 'Amreli', 'Porbandar', 'Kutch', 'Surendranagar', 'Morbi'],
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
      districts: ['Surat', 'Bharuch', 'Ankleshwar', 'Valsad', 'Navsari', 'Rajkot', 'Bhavnagar', 'Jamnagar'],
      code: 'GUJGAS',
      contactPhone: '1800-103-5001',
      activeAlertCount: 0,
    },
    {
      id: 'indane_lpg',
      name: 'Indane LPG (Indian Oil Corporation Ltd)',
      category: 'GAS',
      districts: ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Gandhinagar', 'Bhavnagar', 'Jamnagar', 'Junagadh', 'Kutch'],
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
      districts: ['Gandhinagar', 'Mehsana', 'Patan', 'Banaskantha', 'Kutch', 'Surendranagar', 'Bhavnagar'],
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
      districts: ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Gandhinagar', 'Bhavnagar', 'Jamnagar', 'Junagadh', 'Kutch'],
      code: 'GSRTC',
      contactPhone: '1800-233-6655',
      activeAlertCount: 0,
    },
  ];

  // User link repository
  private static userLinks = new Map<string, CitizenLinkRecord>();

  public static listProviders(category?: ProviderCategory, district?: string): UtilityProvider[] {
    return this.providers.filter((p) => {
      if (category && p.category !== category) return false;
      if (district && !p.districts.some((d) => d.toLowerCase() === district.toLowerCase())) return false;
      return true;
    });
  }

  public static getProviderById(id: string): UtilityProvider | null {
    const found = this.providers.find((p) => p.id === id);
    return found ? { ...found } : null;
  }

  public static getCitizenLinks(userId: string): CitizenProviderLinks {
    const record = this.userLinks.get(userId) || {
      userId,
      electricityProviderId: 'torrent_power', // smart defaults
      gasProviderId: 'adani_png',
      waterProviderId: 'amc_water',
      transitProviderIds: ['gmrc_metro', 'amts_bus'],
      consumerNumbers: {},
      linkedAt: new Date().toISOString(),
    };

    return {
      userId,
      electricityProvider: record.electricityProviderId ? this.getProviderById(record.electricityProviderId) : null,
      gasProvider: record.gasProviderId ? this.getProviderById(record.gasProviderId) : null,
      waterProvider: record.waterProviderId ? this.getProviderById(record.waterProviderId) : null,
      transitProviders: record.transitProviderIds
        .map((id) => this.getProviderById(id))
        .filter((p): p is UtilityProvider => p !== null),
      consumerNumbers: { ...record.consumerNumbers },
      linkedAt: record.linkedAt,
    };
  }

  public static linkCitizenProviders(userId: string, body: LinkProvidersBody): CitizenProviderLinks {
    const existing = this.userLinks.get(userId);
    const updated: CitizenLinkRecord = {
      userId,
      electricityProviderId: body.electricityProviderId !== undefined ? body.electricityProviderId : existing?.electricityProviderId || null,
      gasProviderId: body.gasProviderId !== undefined ? body.gasProviderId : existing?.gasProviderId || null,
      waterProviderId: body.waterProviderId !== undefined ? body.waterProviderId : existing?.waterProviderId || null,
      transitProviderIds: body.transitProviderIds !== undefined ? body.transitProviderIds : existing?.transitProviderIds || [],
      consumerNumbers: {
        ...(existing?.consumerNumbers || {}),
        ...(body.consumerNumbers || {}),
      },
      linkedAt: new Date().toISOString(),
    };

    this.userLinks.set(userId, updated);
    return this.getCitizenLinks(userId);
  }

  /**
   * Broadcast an alert from a provider directly into matching citizens' in-app notification center!
   */
  public static broadcastAlert(providerId: string, body: ProviderBroadcastBody): ProviderBroadcastResponse {
    const provider = this.getProviderById(providerId);
    if (!provider) {
      throw new Error(`Provider with id "${providerId}" not found`);
    }

    const notificationId = crypto.randomUUID();
    const activityRepo = ActivityService.getRepository();

    // Determine matching citizens
    let matchCount = 0;
    for (const [userId, record] of this.userLinks.entries()) {
      const isLinked =
        record.electricityProviderId === providerId ||
        record.gasProviderId === providerId ||
        record.waterProviderId === providerId ||
        record.transitProviderIds.includes(providerId);

      if (isLinked) {
        matchCount++;
        activityRepo.add({
          id: crypto.randomUUID(),
          userId,
          category: body.category || 'ALERT',
          title: `${provider.name}: ${body.title}`,
          message: body.message,
          icon: provider.category === 'ELECTRICITY' ? 'zap' : provider.category === 'WATER' ? 'water' : 'spark',
          coinsEarned: body.incentiveCoins || 0,
          district: body.targetDistrict || provider.districts[0] || 'Gujarat',
          isRead: false,
          createdAt: new Date().toISOString(),
        });
      }
    }

    // Also add to global community feed if target is general
    activityRepo.add({
      id: notificationId,
      userId: null, // Broadcast to all
      category: body.category || 'ALERT',
      title: `${provider.name}: ${body.title}`,
      message: body.message,
      icon: provider.category === 'ELECTRICITY' ? 'zap' : provider.category === 'WATER' ? 'water' : 'spark',
      coinsEarned: body.incentiveCoins || 0,
      district: body.targetDistrict || provider.districts[0] || 'Gujarat',
      isRead: false,
      createdAt: new Date().toISOString(),
    });

    return {
      success: true,
      notificationId,
      dispatchedToCount: Math.max(matchCount, 1),
      message: `Alert successfully dispatched to citizens linked to ${provider.name}`,
    };
  }

  public static getProviderSubscriberCounts(): Record<string, number> {
    const counts: Record<string, number> = {};
    for (const provider of this.providers) {
      counts[provider.id] = 0;
    }

    for (const record of this.userLinks.values()) {
      if (record.electricityProviderId) {
        counts[record.electricityProviderId] = (counts[record.electricityProviderId] ?? 0) + 1;
      }
      if (record.gasProviderId) {
        counts[record.gasProviderId] = (counts[record.gasProviderId] ?? 0) + 1;
      }
      if (record.waterProviderId) {
        counts[record.waterProviderId] = (counts[record.waterProviderId] ?? 0) + 1;
      }
      for (const tId of record.transitProviderIds) {
        counts[tId] = (counts[tId] ?? 0) + 1;
      }
    }

    return counts;
  }
}
