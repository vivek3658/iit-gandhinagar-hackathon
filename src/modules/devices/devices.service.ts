import type {
  DeviceSummaryResponse,
  DeviceTimeLogResponse,
  HighUsageAlertSchema,
  LogHoursBody,
} from './devices.schema';
import type { Static } from '@sinclair/typebox';

type HighUsageAlert = Static<typeof HighUsageAlertSchema>;

interface MasterApplianceSpec {
  id: string;
  name: string;
  category: string;
  icon: string;
  ratedPowerKw: number;
  normalMaxDailyHours: number;
}

const APPLIANCE_SPECS: Record<string, MasterApplianceSpec> = {
  ac: {
    id: 'ac',
    name: 'Inverter Split AC (1.5 Ton)',
    category: 'Cooling',
    icon: '❄️',
    ratedPowerKw: 1.45,
    normalMaxDailyHours: 5.0,
  },
  refrigerator: {
    id: 'refrigerator',
    name: 'Frost-Free Refrigerator',
    category: 'Refrigeration',
    icon: '🧊',
    ratedPowerKw: 0.16,
    normalMaxDailyHours: 14.0,
  },
  geyser: {
    id: 'geyser',
    name: 'Storage Water Geyser',
    category: 'Water Heating',
    icon: '🚿',
    ratedPowerKw: 2.0,
    normalMaxDailyHours: 1.5,
  },
  pump: {
    id: 'pump',
    name: 'Sump Water Pump (1.0 HP)',
    category: 'Water Pumping',
    icon: '💧',
    ratedPowerKw: 1.1,
    normalMaxDailyHours: 1.0,
  },
  induction: {
    id: 'induction',
    name: 'Smart Induction Cooktop',
    category: 'Cooking',
    icon: '🥘',
    ratedPowerKw: 1.5,
    normalMaxDailyHours: 2.0,
  },
  ev_charger: {
    id: 'ev_charger',
    name: 'Electric 2-Wheeler Home Charger',
    category: 'EV Mobility',
    icon: '🛵',
    ratedPowerKw: 0.75,
    normalMaxDailyHours: 4.0,
  },
};

export class DevicesService {
  private static instance: DevicesService;
  private userLogs = new Map<string, Map<string, number>>(); // userId -> (deviceId -> hours)

  public static getInstance(): DevicesService {
    if (!DevicesService.instance) {
      DevicesService.instance = new DevicesService();
    }
    return DevicesService.instance;
  }

  public logDeviceHours(userId: string, body: LogHoursBody): DeviceTimeLogResponse {
    const rawKey = body.deviceCatalogId.toLowerCase().split('_')[0] || 'ac';
    const spec = APPLIANCE_SPECS[rawKey] || {
      id: body.deviceCatalogId,
      name: 'Household Appliance',
      category: 'Electronics',
      icon: '📱',
      ratedPowerKw: 1.0,
      normalMaxDailyHours: 4.0,
    };

    let userMap = this.userLogs.get(userId);
    if (!userMap) {
      userMap = new Map<string, number>();
      this.userLogs.set(userId, userMap);
    }
    userMap.set(spec.id, body.operatingHours);

    // Dynamic temperature power adjustments for AC
    let effectiveKw = spec.ratedPowerKw;
    if (spec.id === 'ac' && body.thermostatTemp) {
      if (body.thermostatTemp < 24) {
        // Each degree below 24 increases compressor load by ~6%
        effectiveKw = Math.round((effectiveKw * (1 + (24 - body.thermostatTemp) * 0.06)) * 100) / 100;
      } else if (body.thermostatTemp > 24) {
        effectiveKw = Math.round((effectiveKw * (1 - (body.thermostatTemp - 24) * 0.04)) * 100) / 100;
      }
    }

    const energyKwh = Math.round(effectiveKw * body.operatingHours * 10) / 10;
    const co2Kg = Math.round(energyKwh * 0.82 * 10) / 10;

    let highUsageAlert: HighUsageAlert | null = null;

    if (body.operatingHours > spec.normalMaxDailyHours) {
      const excess = Math.round((body.operatingHours - spec.normalMaxDailyHours) * 10) / 10;
      const monthlyExcessUnits = excess * effectiveKw * 30;
      const monthlySavingsRupees = Math.round(monthlyExcessUnits * 6.5);
      const monthlyCo2Kg = Math.round(monthlyExcessUnits * 0.82);

      let recommendation = `Reducing daily runtime by ${excess} hours saves ~₹${monthlySavingsRupees}/month.`;
      if (spec.id === 'ac') {
        recommendation =
          `Setting AC sleep timer to 4 hours and thermostat to 24°C saves ₹${monthlySavingsRupees} & ${monthlyCo2Kg} kg CO₂e monthly.`;
      } else if (spec.id === 'geyser') {
        recommendation = `Switching geyser OFF after 30 minutes prevents standby reheat losses of ₹${monthlySavingsRupees}/month.`;
      } else if (spec.id === 'pump') {
        recommendation =
          'Installing a low-cost ₹400 automatic water tank level controller prevents pump dry-runs and water overflows.';
      }

      highUsageAlert = {
        triggered: true,
        alertTitle: `⚠️ High Hours Alert: ${spec.name}`,
        alertMessage: `${spec.name} ran for ${body.operatingHours} hrs today (${excess} hrs above eco threshold of ${spec.normalMaxDailyHours} hrs).`,
        excessHours: excess,
        potentialSavingsRupeesMonthly: monthlySavingsRupees,
        potentialCo2ReductionKgMonthly: monthlyCo2Kg,
        recommendation,
      };
    }

    return {
      loggedDevice: {
        deviceId: spec.id,
        deviceName: spec.name,
        icon: spec.icon,
        operatingHours: body.operatingHours,
        ratedPowerKw: effectiveKw,
        energyConsumedKwh: energyKwh,
        co2EmissionsKg: co2Kg,
      },
      highUsageAlert,
      totalDailyEnergyKwh: energyKwh,
    };
  }

  public getDeviceSummary(userId: string): DeviceSummaryResponse {
    const userMap = this.userLogs.get(userId) || new Map<string, number>();

    const defaultHours: Record<string, number> = {
      ac: 6.5,
      refrigerator: 14.0,
      geyser: 1.2,
      pump: 0.8,
      induction: 1.5,
      ev_charger: 3.5,
    };

    const warnings: string[] = [];
    let monthlyProjectedKwh = 0;

    const devices = Object.values(APPLIANCE_SPECS).map((spec) => {
      const dailyHours = userMap.get(spec.id) ?? defaultHours[spec.id] ?? 2.0;
      const weeklyHours = Math.round(dailyHours * 7 * 10) / 10;
      monthlyProjectedKwh += dailyHours * spec.ratedPowerKw * 30;

      let status: 'OPTIMAL' | 'MODERATE' | 'HIGH_USAGE' = 'OPTIMAL';
      let rec = 'Operating within eco-optimal range.';

      if (dailyHours > spec.normalMaxDailyHours * 1.2) {
        status = 'HIGH_USAGE';
        rec = `High daily usage! Consider scheduling off-peak or using timer limits.`;
        warnings.push(`⚠️ ${spec.name} is running ${dailyHours}h/day. Eco threshold is ${spec.normalMaxDailyHours}h.`);
      } else if (dailyHours > spec.normalMaxDailyHours) {
        status = 'MODERATE';
        rec = 'Approaching upper recommended threshold.';
      }

      return {
        deviceId: spec.id,
        name: spec.name,
        category: spec.category,
        icon: spec.icon,
        ratedPowerKw: spec.ratedPowerKw,
        totalWeeklyHours: weeklyHours,
        avgDailyHours: dailyHours,
        status,
        recommendation: rec,
      };
    });

    const monthlyProjectedBillRupees = Math.round(monthlyProjectedKwh * 6.5);

    return {
      devices,
      highHourWarnings: warnings,
      monthlyProjectedBillRupees,
    };
  }
}
