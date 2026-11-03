import { randomUUID } from 'node:crypto';
import type {
  DeviceSummaryResponse,
  DeviceTimeLogResponse,
  HighUsageAlertSchema,
  LogHoursBody,
  RegisteredDeviceRuntimeBody,
  RegisterDeviceBody,
} from './devices.schema';
import type { Static } from '@sinclair/typebox';
import { ActivityService } from '../activity/activity.service';
import type { Pool } from 'pg';

type HighUsageAlert = Static<typeof HighUsageAlertSchema>;

interface RegisteredDeviceRecord {
  id: string;
  userId: string;
  name: string;
  category: RegisterDeviceBody['category'];
  discoveryMethod: RegisterDeviceBody['discoveryMethod'];
  ratedPowerW: number | null;
  createdAt: string;
  lastLoggedHours: number | null;
  lastEnergyKwh: number | null;
  lastLogDate: string | null;
}

interface RegisteredRuntimeLog {
  operatingHours: number;
  energyConsumedKwh: number | null;
  date: string;
}

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
  private readonly registeredDevices = new Map<string, RegisteredDeviceRecord[]>();
  private readonly registeredLogs = new Map<string, Map<string, RegisteredRuntimeLog>>();

  public constructor(
    private readonly db: Pool | null,
    private readonly allowTestMemory: boolean,
  ) {}

  private async ensureSchema(): Promise<void> {
    if (!this.db) return;
    let ready = DevicesService.schemaReady.get(this.db);
    if (!ready) {
      ready = this.db
        .query(
          `
        CREATE TABLE IF NOT EXISTS public.citizen_registered_devices (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
          name TEXT NOT NULL CHECK (char_length(name) BETWEEN 2 AND 64),
          category TEXT NOT NULL CHECK (category IN ('ac', 'fan', 'refrigerator', 'geyser', 'pump', 'tv', 'other')),
          discovery_method TEXT NOT NULL CHECK (discovery_method IN ('MANUAL', 'BLE', 'MDNS')),
          rated_power_w NUMERIC CHECK (rated_power_w IS NULL OR (rated_power_w > 0 AND rated_power_w <= 20000)),
          created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
        CREATE INDEX IF NOT EXISTS idx_citizen_registered_devices_owner
          ON public.citizen_registered_devices(user_id, created_at DESC);
        CREATE TABLE IF NOT EXISTS public.citizen_device_runtime_logs (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
          registered_device_id UUID NOT NULL REFERENCES public.citizen_registered_devices(id) ON DELETE CASCADE,
          log_date DATE NOT NULL,
          operating_hours NUMERIC NOT NULL CHECK (operating_hours > 0 AND operating_hours <= 24),
          energy_consumed_kwh NUMERIC CHECK (energy_consumed_kwh IS NULL OR energy_consumed_kwh >= 0),
          evidence TEXT NOT NULL CHECK (evidence IN ('RATED_POWER_ESTIMATE', 'RUNTIME_ONLY')),
          created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
          UNIQUE (user_id, registered_device_id, log_date)
        );
        CREATE INDEX IF NOT EXISTS idx_citizen_device_runtime_owner_date
          ON public.citizen_device_runtime_logs(user_id, log_date DESC);
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
      `,
        )
        .then(() => undefined);
      DevicesService.schemaReady.set(this.db, ready);
    }
    await ready;
  }

  public async listRegisteredDevices(userId: string): Promise<RegisteredDeviceRecord[]> {
    if (!this.db) {
      this.requireTestMemory();
      return [...(this.registeredDevices.get(userId) ?? [])].sort((a, b) =>
        b.createdAt.localeCompare(a.createdAt),
      );
    }

    await this.ensureSchema();
    const result = await this.db.query(
      `SELECT d.id, d.user_id, d.name, d.category, d.discovery_method, d.rated_power_w, d.created_at,
              latest.operating_hours, latest.energy_consumed_kwh, latest.log_date
       FROM public.citizen_registered_devices d
       LEFT JOIN LATERAL (
         SELECT operating_hours, energy_consumed_kwh, log_date
         FROM public.citizen_device_runtime_logs
         WHERE user_id = d.user_id AND registered_device_id = d.id
         ORDER BY log_date DESC
         LIMIT 1
       ) latest ON TRUE
       WHERE d.user_id = $1
       ORDER BY d.created_at DESC`,
      [userId],
    );
    return result.rows.map((row) => ({
      id: String(row.id),
      userId: String(row.user_id),
      name: String(row.name),
      category: row.category as RegisterDeviceBody['category'],
      discoveryMethod: row.discovery_method as RegisterDeviceBody['discoveryMethod'],
      ratedPowerW: row.rated_power_w === null ? null : Number(row.rated_power_w),
      createdAt: new Date(row.created_at).toISOString(),
      lastLoggedHours: row.operating_hours === null ? null : Number(row.operating_hours),
      lastEnergyKwh: row.energy_consumed_kwh === null ? null : Number(row.energy_consumed_kwh),
      lastLogDate: row.log_date === null ? null : new Date(row.log_date).toISOString().slice(0, 10),
    }));
  }

  public async registerDevice(
    userId: string,
    body: RegisterDeviceBody,
  ): Promise<RegisteredDeviceRecord> {
    await this.ensureSchema();
    if (this.db) {
      const result = await this.db.query(
        `INSERT INTO public.citizen_registered_devices
           (user_id, name, category, discovery_method, rated_power_w)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING id, user_id, name, category, discovery_method, rated_power_w, created_at`,
        [userId, body.name.trim(), body.category, body.discoveryMethod, body.ratedPowerW ?? null],
      );
      const row = result.rows[0];
      return {
        id: String(row.id),
        userId: String(row.user_id),
        name: String(row.name),
        category: row.category as RegisterDeviceBody['category'],
        discoveryMethod: row.discovery_method as RegisterDeviceBody['discoveryMethod'],
        ratedPowerW: row.rated_power_w === null ? null : Number(row.rated_power_w),
        createdAt: new Date(row.created_at).toISOString(),
        lastLoggedHours: null,
        lastEnergyKwh: null,
        lastLogDate: null,
      };
    }

    this.requireTestMemory();
    const device: RegisteredDeviceRecord = {
      id: randomUUID(),
      userId,
      name: body.name.trim(),
      category: body.category,
      discoveryMethod: body.discoveryMethod,
      ratedPowerW: body.ratedPowerW ?? null,
      createdAt: new Date().toISOString(),
      lastLoggedHours: null,
      lastEnergyKwh: null,
      lastLogDate: null,
    };
    this.registeredDevices.set(userId, [device, ...(this.registeredDevices.get(userId) ?? [])]);
    return device;
  }

  public async removeRegisteredDevice(userId: string, deviceId: string): Promise<boolean> {
    if (this.db) {
      await this.ensureSchema();
      const result = await this.db.query(
        'DELETE FROM public.citizen_registered_devices WHERE user_id = $1 AND id = $2',
        [userId, deviceId],
      );
      return (result.rowCount ?? 0) > 0;
    }

    this.requireTestMemory();
    const existing = this.registeredDevices.get(userId) ?? [];
    const remaining = existing.filter((device) => device.id !== deviceId);
    this.registeredDevices.set(userId, remaining);
    this.registeredLogs.delete(deviceId);
    return remaining.length !== existing.length;
  }

  public async logRegisteredRuntime(
    userId: string,
    deviceId: string,
    body: RegisteredDeviceRuntimeBody,
  ): Promise<{
    deviceId: string;
    operatingHours: number;
    energyConsumedKwh: number | null;
    energyEvidence: 'RATED_POWER_ESTIMATE' | 'RUNTIME_ONLY';
    co2EmissionsKg: null;
    date: string;
  } | null> {
    const date = body.date ?? new Date().toISOString().slice(0, 10);
    if (this.db) {
      await this.ensureSchema();
      const deviceResult = await this.db.query(
        `SELECT rated_power_w FROM public.citizen_registered_devices
         WHERE id = $1 AND user_id = $2`,
        [deviceId, userId],
      );
      if (!deviceResult.rows[0]) return null;
      const ratedPowerW =
        deviceResult.rows[0].rated_power_w === null
          ? null
          : Number(deviceResult.rows[0].rated_power_w);
      const energyKwh =
        ratedPowerW === null
          ? null
          : Math.round((ratedPowerW * body.operatingHours * 100) / 1000) / 100;
      const evidence = ratedPowerW === null ? 'RUNTIME_ONLY' : 'RATED_POWER_ESTIMATE';
      await this.db.query(
        `INSERT INTO public.citizen_device_runtime_logs
           (user_id, registered_device_id, log_date, operating_hours, energy_consumed_kwh, evidence)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT (user_id, registered_device_id, log_date) DO UPDATE SET
           operating_hours = EXCLUDED.operating_hours,
           energy_consumed_kwh = EXCLUDED.energy_consumed_kwh,
           evidence = EXCLUDED.evidence,
           created_at = NOW()`,
        [userId, deviceId, date, body.operatingHours, energyKwh, evidence],
      );
      return {
        deviceId,
        operatingHours: body.operatingHours,
        energyConsumedKwh: energyKwh,
        energyEvidence: evidence,
        co2EmissionsKg: null,
        date,
      };
    }

    this.requireTestMemory();
    const device = (this.registeredDevices.get(userId) ?? []).find(
      (candidate) => candidate.id === deviceId,
    );
    if (!device) return null;
    const energyKwh =
      device.ratedPowerW === null
        ? null
        : Math.round((device.ratedPowerW * body.operatingHours * 100) / 1000) / 100;
    this.registeredLogs.set(deviceId, this.registeredLogs.get(deviceId) ?? new Map());
    this.registeredLogs.get(deviceId)!.set(date, {
      operatingHours: body.operatingHours,
      energyConsumedKwh: energyKwh,
      date,
    });
    device.lastLoggedHours = body.operatingHours;
    device.lastEnergyKwh = energyKwh;
    device.lastLogDate = date;
    return {
      deviceId,
      operatingHours: body.operatingHours,
      energyConsumedKwh: energyKwh,
      energyEvidence: device.ratedPowerW === null ? 'RUNTIME_ONLY' : 'RATED_POWER_ESTIMATE',
      co2EmissionsKg: null,
      date,
    };
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
        effectiveKw = Math.round(effectiveKw * (1 + (24 - body.thermostatTemp) * 0.06) * 100) / 100;
      } else if (body.thermostatTemp > 24) {
        effectiveKw = Math.round(effectiveKw * (1 - (body.thermostatTemp - 24) * 0.04) * 100) / 100;
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
      const weeklyHours =
        Math.round(recentLogs.reduce((sum, entry) => sum + entry.operatingHours, 0) * 10) / 10;
      const dailyHours = recentLogs.length
        ? Math.round((weeklyHours / recentLogs.length) * 10) / 10
        : 0;

      let status: 'OPTIMAL' | 'MODERATE' | 'HIGH_USAGE' = 'OPTIMAL';
      let rec = 'Operating within eco-optimal range.';

      if (dailyHours > spec.normalMaxDailyHours * 1.2) {
        status = 'HIGH_USAGE';
        rec = `High daily usage! Consider scheduling off-peak or using timer limits.`;
        warnings.push(
          `⚠️ ${spec.name} is running ${dailyHours}h/day. Eco threshold is ${spec.normalMaxDailyHours}h.`,
        );
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
