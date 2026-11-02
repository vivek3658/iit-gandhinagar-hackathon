import type {
  DeviceSummaryResponse,
  DeviceTimeLogResponse,
  HighUsageAlertSchema,
  LogHoursBody,
} from './devices.schema';
import type { Static } from '@sinclair/typebox';
import { ActivityService } from '../activity/activity.service';
import type { Pool } from 'pg';

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

interface DeviceRuntimeLog {
  date: string;
  operatingHours: number;
  energyConsumedKwh: number;
  effectiveKw: number;
  deviceId: string;
}

export class DevicesService {
  private static schemaReady = new WeakMap<Pool, Promise<void>>();
  private userLogs = new Map<string, Map<string, DeviceRuntimeLog[]>>();

  public constructor(
    private readonly db: Pool | null,
    private readonly allowTestMemory: boolean,
  ) {}

  private async ensureSchema(): Promise<void> {
    if (!this.db) return;
    let ready = DevicesService.schemaReady.get(this.db);
    if (!ready) {
      ready = this.db.query(`
        CREATE TABLE IF NOT EXISTS public.device_runtime_logs (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
          device_id TEXT NOT NULL,
          log_date DATE NOT NULL,
          operating_hours NUMERIC NOT NULL CHECK (operating_hours > 0 AND operating_hours <= 24),
          rated_power_kw NUMERIC NOT NULL CHECK (rated_power_kw > 0),
          energy_consumed_kwh NUMERIC NOT NULL CHECK (energy_consumed_kwh >= 0),
          created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
          updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
          UNIQUE (user_id, device_id, log_date)
        );
        CREATE INDEX IF NOT EXISTS idx_device_runtime_logs_owner_date
          ON public.device_runtime_logs(user_id, log_date DESC);
      `).then(() => undefined);
      DevicesService.schemaReady.set(this.db, ready);
    }
    await ready;
  }

  private requireTestMemory(): void {
    if (!this.allowTestMemory) {
      throw new Error('PostgreSQL is required for persistent device runtime logs.');
    }
  }

  public async logDeviceHours(userId: string, body: LogHoursBody): Promise<DeviceTimeLogResponse> {
    const catalogId = body.deviceCatalogId.toLowerCase();
    const rawKey = APPLIANCE_SPECS[catalogId] ? catalogId : catalogId.split('_')[0] || 'ac';
    const spec = APPLIANCE_SPECS[rawKey] || {
      id: body.deviceCatalogId,
      name: 'Household Appliance',
      category: 'Electronics',
      icon: '📱',
      ratedPowerKw: 1.0,
      normalMaxDailyHours: 4.0,
    };

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
    const date = body.date ?? new Date().toISOString().slice(0, 10);
    if (this.db) {
      await this.ensureSchema();
      await this.db.query(
        `INSERT INTO public.device_runtime_logs
           (user_id, device_id, log_date, operating_hours, rated_power_kw, energy_consumed_kwh)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT (user_id, device_id, log_date) DO UPDATE SET
           operating_hours = EXCLUDED.operating_hours,
           rated_power_kw = EXCLUDED.rated_power_kw,
           energy_consumed_kwh = EXCLUDED.energy_consumed_kwh,
           updated_at = NOW()`,
        [userId, spec.id, date, body.operatingHours, effectiveKw, energyKwh],
      );
    } else {
      this.requireTestMemory();
      let userMap = this.userLogs.get(userId);
      if (!userMap) {
        userMap = new Map<string, DeviceRuntimeLog[]>();
        this.userLogs.set(userId, userMap);
      }
      const deviceLogs = userMap.get(spec.id) ?? [];
      const entry: DeviceRuntimeLog = {
        deviceId: spec.id,
        date,
        operatingHours: body.operatingHours,
        energyConsumedKwh: energyKwh,
        effectiveKw,
      };
      const existingIndex = deviceLogs.findIndex((log) => log.date === date);
      if (existingIndex >= 0) deviceLogs[existingIndex] = entry;
      else deviceLogs.push(entry);
      userMap.set(spec.id, deviceLogs);
    }

    await ActivityService.postActivity({
      userId,
      category: 'HABIT',
      title: `${spec.name} runtime logged`,
      message: `${body.operatingHours} hours · ${energyKwh.toFixed(1)} kWh estimated from rated appliance power.`,
      icon: 'zap',
    });

    let highUsageAlert: HighUsageAlert | null = null;

    if (body.operatingHours > spec.normalMaxDailyHours) {
      const excess = Math.round((body.operatingHours - spec.normalMaxDailyHours) * 10) / 10;
      let recommendation = `Reducing daily runtime by ${excess} hours may reduce energy use.`;
      if (spec.id === 'ac') {
        recommendation = 'Consider using a sleep timer and a comfortable thermostat setting.';
      } else if (spec.id === 'geyser') {
        recommendation = 'Consider turning the geyser off when hot water is no longer needed.';
      } else if (spec.id === 'pump') {
        recommendation = 'Consider a tank-level controller to reduce unnecessary pump runtime.';
      }

      highUsageAlert = {
        triggered: true,
        alertTitle: `⚠️ High Hours Alert: ${spec.name}`,
        alertMessage: `${spec.name} ran for ${body.operatingHours} hrs on ${date} (${excess} hrs above the reference threshold of ${spec.normalMaxDailyHours} hrs).`,
        excessHours: excess,
        potentialSavingsRupeesMonthly: null,
        potentialCo2ReductionKgMonthly: null,
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
        energyEvidence: 'RATED_POWER_ESTIMATE',
        co2EmissionsKg: null,
      },
      highUsageAlert,
      totalDailyEnergyKwh: energyKwh,
    };
  }

  public async getDeviceSummary(userId: string): Promise<DeviceSummaryResponse> {
    let userMap = this.userLogs.get(userId) || new Map<string, DeviceRuntimeLog[]>();
    if (this.db) {
      await this.ensureSchema();
      const result = await this.db.query(
        `SELECT device_id, log_date, operating_hours, rated_power_kw, energy_consumed_kwh
         FROM public.device_runtime_logs
         WHERE user_id = $1 AND log_date >= CURRENT_DATE - INTERVAL '6 days'
         ORDER BY log_date DESC`,
        [userId],
      );
      userMap = new Map<string, DeviceRuntimeLog[]>();
      for (const row of result.rows) {
        const logs = userMap.get(row.device_id) ?? [];
        logs.push({
          deviceId: row.device_id,
          date: new Date(row.log_date).toISOString().slice(0, 10),
          operatingHours: Number(row.operating_hours),
          effectiveKw: Number(row.rated_power_kw),
          energyConsumedKwh: Number(row.energy_consumed_kwh),
        });
        userMap.set(row.device_id, logs);
      }
    } else {
      this.requireTestMemory();
    }

    const warnings: string[] = [];

    const devices = Object.values(APPLIANCE_SPECS).map((spec) => {
      const logs = userMap.get(spec.id) ?? [];
      const recentLogs = logs.slice(-7);
      const weeklyHours = Math.round(recentLogs.reduce((sum, entry) => sum + entry.operatingHours, 0) * 10) / 10;
      const dailyHours = recentLogs.length ? Math.round((weeklyHours / recentLogs.length) * 10) / 10 : 0;

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

    return {
      devices,
      highHourWarnings: warnings,
      monthlyProjectedBillRupees: null,
    };
  }
}
