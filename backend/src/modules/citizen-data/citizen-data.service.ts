import { randomUUID } from 'node:crypto';
import type { Pool } from 'pg';
import type {
  Trip,
  TripBody,
  UtilityReading,
  UtilityReadingBody,
  Vehicle,
  VehicleBody,
} from './citizen-data.schema';

export class CitizenDataService {
  private static schemas = new WeakMap<Pool, Promise<void>>();
  private static testRecords = new Map<
    string,
    { readings: UtilityReading[]; vehicles: Vehicle[]; trips: Trip[] }
  >();

  public constructor(
    private readonly db: Pool | null,
    private readonly allowTestMemory: boolean,
  ) {}

  public static async prepare(db: Pool): Promise<void> {
    const service = new CitizenDataService(db, false);
    await service.ensureSchema();
  }

  public async listReadings(userId: string): Promise<UtilityReading[]> {
    if (!this.db) return this.inMemory(userId).readings.slice(0, 100);
    await this.ensureSchema();
    const result = await this.db.query(
      `SELECT id, utility, value, unit, period_start, period_end, provider_id,
              source_reference, created_at
       FROM utility_readings WHERE user_id = $1
       ORDER BY period_end DESC, created_at DESC LIMIT 100`,
      [userId],
    );
    return result.rows.map((row) => this.readingFromRow(row));
  }

  public async createReading(userId: string, input: UtilityReadingBody): Promise<UtilityReading> {
    this.validateReading(input);
    if (!this.db) {
      const reading: UtilityReading = {
        id: randomUUID(),
        ...input,
        providerId: input.providerId ?? null,
        sourceReference: input.sourceReference ?? null,
        evidenceTier: 'USER_ENTERED',
        createdAt: new Date().toISOString(),
      };
      this.inMemory(userId).readings.unshift(reading);
      return reading;
    }

    await this.ensureSchema();
    const result = await this.db.query(
      `INSERT INTO utility_readings
         (user_id, utility, value, unit, period_start, period_end, provider_id, source_reference)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING id, utility, value, unit, period_start, period_end, provider_id,
                 source_reference, created_at`,
      [
        userId,
        input.utility,
        input.value,
        input.unit,
        input.periodStart,
        input.periodEnd,
        input.providerId ?? null,
        input.sourceReference ?? null,
      ],
    );
    return this.readingFromRow(result.rows[0]);
  }

  public async listVehicles(userId: string): Promise<Vehicle[]> {
    if (!this.db) return [...this.inMemory(userId).vehicles];
    await this.ensureSchema();
    const result = await this.db.query(
      `SELECT id, label, vehicle_type, fuel_type, make, model, model_year, efficiency,
              efficiency_unit, registration_label, created_at, updated_at
       FROM citizen_vehicles WHERE user_id = $1 AND deleted_at IS NULL
       ORDER BY created_at`,
      [userId],
    );
    return result.rows.map((row) => this.vehicleFromRow(row));
  }

  public async createVehicle(userId: string, input: VehicleBody): Promise<Vehicle> {
    if (!this.db) {
      const now = new Date().toISOString();
      const vehicle = { id: randomUUID(), ...input, createdAt: now, updatedAt: now };
      this.inMemory(userId).vehicles.push(vehicle);
      return vehicle;
    }
    await this.ensureSchema();
    const result = await this.db.query(
      `INSERT INTO citizen_vehicles
         (user_id, label, vehicle_type, fuel_type, make, model, model_year, efficiency,
          efficiency_unit, registration_label)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
       RETURNING id, label, vehicle_type, fuel_type, make, model, model_year, efficiency,
                 efficiency_unit, registration_label, created_at, updated_at`,
      [
        userId,
        input.label,
        input.vehicleType,
        input.fuelType,
        input.make ?? null,
        input.model ?? null,
        input.modelYear ?? null,
        input.efficiency ?? null,
        input.efficiencyUnit ?? null,
        input.registrationLabel ?? null,
      ],
    );
    return this.vehicleFromRow(result.rows[0]);
  }

  public async updateVehicle(
    userId: string,
    vehicleId: string,
    input: VehicleBody,
  ): Promise<Vehicle | null> {
    if (!this.db) {
      const vehicles = this.inMemory(userId).vehicles;
      const index = vehicles.findIndex((vehicle) => vehicle.id === vehicleId);
      if (index < 0) return null;
      const current = vehicles[index];
      if (!current) return null;
      vehicles[index] = { ...current, ...input, updatedAt: new Date().toISOString() };
      return vehicles[index];
    }
    await this.ensureSchema();
    const result = await this.db.query(
      `UPDATE citizen_vehicles
       SET label = $3, vehicle_type = $4, fuel_type = $5, make = $6, model = $7,
           model_year = $8, efficiency = $9, efficiency_unit = $10,
           registration_label = $11, updated_at = NOW()
       WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL
       RETURNING id, label, vehicle_type, fuel_type, make, model, model_year, efficiency,
                 efficiency_unit, registration_label, created_at, updated_at`,
      [
        vehicleId,
        userId,
        input.label,
        input.vehicleType,
        input.fuelType,
        input.make ?? null,
        input.model ?? null,
        input.modelYear ?? null,
        input.efficiency ?? null,
        input.efficiencyUnit ?? null,
        input.registrationLabel ?? null,
      ],
    );
    return result.rows[0] ? this.vehicleFromRow(result.rows[0]) : null;
  }

  public async deleteVehicle(userId: string, vehicleId: string): Promise<boolean> {
    if (!this.db) {
      const vehicles = this.inMemory(userId).vehicles;
      const index = vehicles.findIndex((vehicle) => vehicle.id === vehicleId);
      if (index < 0) return false;
      vehicles.splice(index, 1);
      return true;
    }
    await this.ensureSchema();
    const result = await this.db.query(
      `UPDATE citizen_vehicles SET deleted_at = NOW(), updated_at = NOW()
       WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL RETURNING id`,
      [vehicleId, userId],
    );
    return result.rowCount === 1;
  }

  public async listTrips(userId: string): Promise<Trip[]> {
    if (!this.db) return [...this.inMemory(userId).trips];
    await this.ensureSchema();
    const result = await this.db.query(
      `SELECT id, mode, distance_km, started_at, ended_at, vehicle_id, created_at
       FROM confirmed_trips WHERE user_id = $1
       ORDER BY started_at DESC LIMIT 100`,
      [userId],
    );
    return result.rows.map((row) => this.tripFromRow(row));
  }

  public async createTrip(userId: string, input: TripBody): Promise<Trip> {
    this.validateTrip(input);
    if (!this.db) {
      if (
        input.vehicleId &&
        !this.inMemory(userId).vehicles.some((vehicle) => vehicle.id === input.vehicleId)
      ) {
        throw new Error('Vehicle not found for this citizen.');
      }
      const trips = this.inMemory(userId).trips;
      const duplicate = trips.find(
        (trip) =>
          (trip as Trip & { idempotencyKey?: string }).idempotencyKey === input.idempotencyKey,
      );
      if (duplicate) {
        if (!this.matchesTrip(duplicate, input)) {
          throw new Error('Idempotency key was already used for a different trip.');
        }
        return duplicate;
      }
      const trip: Trip = {
        id: randomUUID(),
        mode: input.mode,
        distanceKm: input.distanceKm,
        startedAt: input.startedAt,
        endedAt: input.endedAt,
        vehicleId: input.vehicleId ?? null,
        evidenceTier: 'USER_CONFIRMED_SUMMARY',
        co2eKg: null,
        createdAt: new Date().toISOString(),
      };
      trips.unshift(Object.assign(trip, { idempotencyKey: input.idempotencyKey }));
      return trip;
    }

    await this.ensureSchema();
    if (input.vehicleId) {
      const vehicle = await this.db.query(
        `SELECT id FROM citizen_vehicles
         WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL`,
        [input.vehicleId, userId],
      );
      if (!vehicle.rows[0]) {
        throw new Error('Vehicle not found for this citizen.');
      }
    }
    const result = await this.db.query(
      `INSERT INTO confirmed_trips
         (user_id, idempotency_key, mode, distance_km, started_at, ended_at, vehicle_id, notes)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       ON CONFLICT (user_id, idempotency_key) DO NOTHING
       RETURNING id, mode, distance_km, started_at, ended_at, vehicle_id, created_at`,
      [
        userId,
        input.idempotencyKey,
        input.mode,
        input.distanceKm,
        input.startedAt,
        input.endedAt,
        input.vehicleId ?? null,
        input.notes ?? null,
      ],
    );
    if (result.rows[0]) return this.tripFromRow(result.rows[0]);

    const existing = await this.db.query(
      `SELECT id, mode, distance_km, started_at, ended_at, vehicle_id, created_at
       FROM confirmed_trips WHERE user_id = $1 AND idempotency_key = $2`,
      [userId, input.idempotencyKey],
    );
    if (!existing.rows[0]) {
      throw new Error('Trip save could not be confirmed.');
    }
    const trip = this.tripFromRow(existing.rows[0]);
    if (!this.matchesTrip(trip, input)) {
      throw new Error('Idempotency key was already used for a different trip.');
    }
    return trip;
  }

  private matchesTrip(trip: Trip, input: TripBody): boolean {
    return (
      trip.mode === input.mode &&
      trip.distanceKm === input.distanceKm &&
      trip.startedAt === new Date(input.startedAt).toISOString() &&
      trip.endedAt === new Date(input.endedAt).toISOString() &&
      trip.vehicleId === (input.vehicleId ?? null)
    );
  }

  private validateReading(input: UtilityReadingBody): void {
    const allowedUnits: Record<UtilityReadingBody['utility'], string[]> = {
      ELECTRICITY: ['kWh'],
      WATER: ['L', 'm3'],
      GAS: ['kg', 'm3', 'L'],
    };
    if (!allowedUnits[input.utility].includes(input.unit)) {
      throw new Error(`Unit "${input.unit}" is not supported for ${input.utility}.`);
    }
    if (input.periodStart > input.periodEnd) {
      throw new Error('Reading period start must not be after its end.');
    }
  }

  private validateTrip(input: TripBody): void {
    if (input.endedAt <= input.startedAt) {
      throw new Error('Trip end time must be after its start time.');
    }
    if (input.mode === 'PRIVATE_VEHICLE' && !input.vehicleId) {
      throw new Error('A vehicle is required for a private-vehicle trip.');
    }
    if (input.mode !== 'PRIVATE_VEHICLE' && input.vehicleId) {
      throw new Error('A vehicle can only be attached to a private-vehicle trip.');
    }
  }

  private async ensureSchema(): Promise<void> {
    if (!this.db) return;
    let ready = CitizenDataService.schemas.get(this.db);
    if (!ready) {
      ready = this.db
        .query(
          `
          CREATE TABLE IF NOT EXISTS utility_readings (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            utility TEXT NOT NULL CHECK (utility IN ('ELECTRICITY', 'WATER', 'GAS')),
            value NUMERIC NOT NULL CHECK (value > 0),
            unit TEXT NOT NULL,
            period_start DATE NOT NULL,
            period_end DATE NOT NULL,
            provider_id TEXT,
            source_reference TEXT,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            CHECK (period_start <= period_end)
          );
          CREATE INDEX IF NOT EXISTS idx_utility_readings_user_period
            ON utility_readings(user_id, period_end DESC);
          CREATE TABLE IF NOT EXISTS citizen_vehicles (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            label TEXT NOT NULL,
            vehicle_type TEXT NOT NULL,
            fuel_type TEXT NOT NULL,
            make TEXT,
            model TEXT,
            model_year INTEGER,
            efficiency NUMERIC,
            efficiency_unit TEXT,
            registration_label TEXT,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            deleted_at TIMESTAMPTZ
          );
          CREATE INDEX IF NOT EXISTS idx_citizen_vehicles_owner
            ON citizen_vehicles(user_id) WHERE deleted_at IS NULL;
          CREATE TABLE IF NOT EXISTS confirmed_trips (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            idempotency_key TEXT NOT NULL,
            mode TEXT NOT NULL,
            distance_km NUMERIC NOT NULL CHECK (distance_km > 0 AND distance_km <= 2000),
            started_at TIMESTAMPTZ NOT NULL,
            ended_at TIMESTAMPTZ NOT NULL,
            vehicle_id UUID REFERENCES citizen_vehicles(id) ON DELETE SET NULL,
            notes TEXT,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            UNIQUE (user_id, idempotency_key),
            CHECK (ended_at > started_at)
          );
          CREATE INDEX IF NOT EXISTS idx_confirmed_trips_user_started
            ON confirmed_trips(user_id, started_at DESC);
        `,
        )
        .then(() => undefined)
        .catch((error: unknown) => {
          CitizenDataService.schemas.delete(this.db!);
          throw error;
        });
      CitizenDataService.schemas.set(this.db, ready);
    }
    await ready;
  }

  private inMemory(userId: string) {
    if (!this.allowTestMemory) {
      throw new Error('PostgreSQL is required for citizen data in this environment.');
    }
    let records = CitizenDataService.testRecords.get(userId);
    if (!records) {
      records = { readings: [], vehicles: [], trips: [] };
      CitizenDataService.testRecords.set(userId, records);
    }
    return records;
  }

  private readingFromRow(row: Record<string, unknown>): UtilityReading {
    return {
      id: String(row.id),
      utility: row.utility as UtilityReading['utility'],
      value: Number(row.value),
      unit: String(row.unit),
      periodStart: this.dateValue(row.period_start),
      periodEnd: this.dateValue(row.period_end),
      providerId: row.provider_id ? String(row.provider_id) : null,
      sourceReference: row.source_reference ? String(row.source_reference) : null,
      evidenceTier: 'USER_ENTERED',
      createdAt: new Date(String(row.created_at)).toISOString(),
    };
  }

  private vehicleFromRow(row: Record<string, unknown>): Vehicle {
    return {
      id: String(row.id),
      label: String(row.label),
      vehicleType: row.vehicle_type as Vehicle['vehicleType'],
      fuelType: row.fuel_type as Vehicle['fuelType'],
      make: row.make ? String(row.make) : undefined,
      model: row.model ? String(row.model) : undefined,
      modelYear: row.model_year ? Number(row.model_year) : undefined,
      efficiency: row.efficiency === null ? undefined : Number(row.efficiency),
      efficiencyUnit: row.efficiency_unit ? String(row.efficiency_unit) : undefined,
      registrationLabel: row.registration_label ? String(row.registration_label) : undefined,
      createdAt: new Date(String(row.created_at)).toISOString(),
      updatedAt: new Date(String(row.updated_at)).toISOString(),
    };
  }

  private tripFromRow(row: Record<string, unknown>): Trip {
    return {
      id: String(row.id),
      mode: row.mode as Trip['mode'],
      distanceKm: Number(row.distance_km),
      startedAt: new Date(String(row.started_at)).toISOString(),
      endedAt: new Date(String(row.ended_at)).toISOString(),
      vehicleId: row.vehicle_id ? String(row.vehicle_id) : null,
      evidenceTier: 'USER_CONFIRMED_SUMMARY',
      co2eKg: null,
      createdAt: new Date(String(row.created_at)).toISOString(),
    };
  }

  private dateValue(value: unknown): string {
    if (value instanceof Date) return value.toISOString().slice(0, 10);
    return String(value).slice(0, 10);
  }
}
