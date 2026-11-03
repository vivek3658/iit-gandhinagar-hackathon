'use client';

import { useCallback, useEffect, useState } from 'react';
import type { FormEvent } from 'react';
import './operator.css';

type OperatorIdentity = {
  role: 'ADMIN' | 'PROVIDER_ADMIN' | 'CITY_ADMIN';
  tenantId: string | null;
  tenantType: 'PROVIDER' | 'CITY' | null;
};
type Campaign = {
  id: string;
  title: string;
  category: string;
  status: string;
  recipientCount: number;
  deliveredCount: number;
  scheduledAt: string;
  targetDistrict: string | null;
  targetWard: string | null;
  targetProviderId: string | null;
};
type Schedule = {
  id: string;
  district: string;
  ward: string;
  wasteType: string;
  pickupWeekdays: number[];
  collectionWindow: string;
  effectiveFrom: string;
  effectiveTo: string | null;
  notes: string | null;
  isActive: boolean;
};
type AuditItem = {
  id: string;
  actorEmail: string;
  action: string;
  resourceType: string;
  reason: string | null;
  createdAt: string;
};
type TenantAdmin = {
  id: string;
  email: string;
  displayName: string;
  tenantType: 'PROVIDER' | 'CITY';
  tenantId: string;
  districts: string[];
};
type TenantOverview = {
  activeCitizens: number;
  campaignOptIns: number;
  wasteReminderOptIns: number;
  scopeLabel: string;
};
type PlatformKpis = {
  totalRegisteredCitizens: number;
  activeSanctuariesCount: number | null;
  totalCo2eSavedKg: number | null;
  totalPeakMwhShifted: number | null;
  totalCoinsInCirculation: number;
  districtBreakdown: Record<string, number>;
  wardBreakdown: Array<{ district: string; ward: string; citizenCount: number }>;
  utilityUsage: Array<{
    utility: 'ELECTRICITY' | 'WATER' | 'GAS';
    district: string;
    ward: string;
    unit: string;
    period: string;
    averageValue: number;
    contributors: number;
  }>;
  estimatedCommuteCo2eKg: number | null;
  estimatedImpactByArea: Array<{
    district: string;
    ward: string;
    estimatedCo2eKg: number;
    contributors: number;
  }>;
  providerSubscribers: Record<string, number> | null;
  householdAnalytics: {
    consentedCitizens: number | null;
    registeredDevices: number | null;
    estimatedEnergyKwh: number | null;
    utilityReadings: number | null;
    runtimeLogs: number | null;
    confirmedTrips: number | null;
  };
};
const utilityLabels = {
  ELECTRICITY: 'Electricity',
  WATER: 'Water',
  GAS: 'Gas',
} as const;
type Provider = {
  id: string;
  name: string;
  category: string;
  districts: string[];
  code: string;
  contactPhone: string;
  status?: string;
};
type ApiResult<T> = T & { message?: string };

async function api<T>(path: string, init?: RequestInit): Promise<ApiResult<T>> {
  const response = await fetch(`/api/operator/proxy/${path}`, {
    ...init,
    headers: { 'content-type': 'application/json', ...init?.headers },
    cache: 'no-store',
  });
  const result = (await response.json()) as ApiResult<T>;
  if (!response.ok) throw new Error(result.message ?? `Request failed (${response.status}).`);
  return result;
}

const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const localDate = (() => {
  const date = new Date(Date.now() + 330 * 60_000);
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
})();

export default function OperatorPage() {
  const [identity, setIdentity] = useState<OperatorIdentity | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [campaigns, setCampaigns] = useState<Campaign[]>([]);
  const [schedules, setSchedules] = useState<Schedule[]>([]);
  const [audit, setAudit] = useState<AuditItem[]>([]);
  const [tenantAdmins, setTenantAdmins] = useState<TenantAdmin[]>([]);
  const [tenantOverview, setTenantOverview] = useState<TenantOverview | null>(null);
  const [platformKpis, setPlatformKpis] = useState<PlatformKpis | null>(null);
  const [providers, setProviders] = useState<Provider[]>([]);
  const [message, setMessage] = useState('');

  const load = useCallback(async () => {
    setError('');
    try {
      const tenant = await api<OperatorIdentity & { displayName: string; districts: string[] }>(
        'admin/tenant/me',
      );
      setIdentity(tenant);
      const [campaignData, auditData, overviewData] = await Promise.all([
        api<{ campaigns: Campaign[] }>('admin/campaigns'),
        api<{ items: AuditItem[] }>('admin/audit'),
        api<TenantOverview>('admin/tenant/overview'),
      ]);
      setCampaigns(campaignData.campaigns);
      setAudit(auditData.items);
      setTenantOverview(overviewData);
      if (tenant.role === 'CITY_ADMIN') {
        const scheduleData = await api<{ schedules: Schedule[] }>('waste/admin/schedules');
        setSchedules(scheduleData.schedules);
      }
    } catch (tenantError) {
      try {
        const adminData = await api<{ kpis: PlatformKpis }>('admin/kpis');
        setIdentity({ role: 'ADMIN', tenantId: null, tenantType: null });
        setPlatformKpis(adminData.kpis);
        setTenantOverview(null);
        setMessage(
          `Platform data ready: ${adminData.kpis.totalRegisteredCitizens} citizens, ${adminData.kpis.totalCoinsInCirculation} coins.`,
        );
        const [campaignData, auditData, adminsData, providerData] = await Promise.all([
          api<{ campaigns: Campaign[] }>('admin/campaigns'),
          api<{ items: AuditItem[] }>('admin/audit'),
          api<{ admins: TenantAdmin[] }>('admin/tenant-admins'),
          api<{ providers: Provider[] }>('admin/providers'),
        ]);
        setCampaigns(campaignData.campaigns);
        setAudit(auditData.items);
        setTenantAdmins(adminsData.admins);
        setProviders(providerData.providers);
      } catch {
        setIdentity(null);
        setError(tenantError instanceof Error ? tenantError.message : 'Sign in to continue.');
      }
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  async function login(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const formElement = event.currentTarget;
    setError('');
    const form = new FormData(formElement);
    try {
      const response = await fetch('/api/operator/login', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ username: form.get('username'), password: form.get('password') }),
      });
      const result = (await response.json()) as { message?: string };
      if (!response.ok) {
        setError(result.message ?? 'Login failed.');
        return;
      }
    } catch {
      setError('The operator sign-in service is unavailable.');
      return;
    }
    formElement.reset();
    setLoading(true);
    await load();
  }

  async function logout() {
    await fetch('/api/operator/logout', { method: 'POST' });
    setIdentity(null);
    setCampaigns([]);
    setSchedules([]);
    setAudit([]);
    setTenantAdmins([]);
    setTenantOverview(null);
    setMessage('');
  }

  async function submitCampaign(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const formElement = event.currentTarget;
    const form = new FormData(formElement);
    try {
      const result = await api<Campaign>('admin/campaigns', {
        method: 'POST',
        body: JSON.stringify({
          title: form.get('title'),
          message: form.get('message'),
          category: form.get('category'),
          targetDistrict: form.get('district') || undefined,
          targetWard: form.get('ward') || undefined,
          targetProviderId: form.get('targetProviderId') || undefined,
          scheduledAt: form.get('scheduledAt')
            ? new Date(String(form.get('scheduledAt'))).toISOString()
            : undefined,
          reason: form.get('reason'),
        }),
      });
      setMessage(
        result.recipientCount === 0
          ? 'Campaign saved, but no opted-in citizens matched this audience. Check the city, ward, provider links, and citizens’ campaign notification preferences.'
          : new Date(result.scheduledAt).getTime() > Date.now()
            ? `Campaign scheduled for ${result.recipientCount} opted-in citizens.`
            : `Campaign delivered to ${result.deliveredCount} of ${result.recipientCount} opted-in citizens’ in-app feeds.`,
      );
      formElement.reset();
      await load();
    } catch (submitError) {
      setError(submitError instanceof Error ? submitError.message : 'Campaign could not be saved.');
    }
  }

  async function submitSchedule(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const formElement = event.currentTarget;
    const form = new FormData(formElement);
    const body = {
      district: form.get('district'),
      ward: form.get('ward'),
      wasteType: form.get('wasteType'),
      pickupWeekdays: String(form.get('weekdays'))
        .split(',')
        .map((day) => Number(day.trim()))
        .filter(Number.isInteger),
      collectionWindow: form.get('collectionWindow'),
      effectiveFrom: form.get('effectiveFrom'),
      effectiveTo: form.get('effectiveTo') || null,
      notes: form.get('notes'),
      reason: form.get('reason'),
    };
    try {
      await api<Schedule>('waste/admin/schedules', { method: 'POST', body: JSON.stringify(body) });
      setMessage('Effective-dated collection schedule saved.');
      formElement.reset();
      await load();
    } catch (submitError) {
      setError(submitError instanceof Error ? submitError.message : 'Schedule could not be saved.');
    }
  }

  async function submitTenantAdmin(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const formElement = event.currentTarget;
    const form = new FormData(formElement);
    try {
      await api<TenantAdmin>('admin/tenant-admins', {
        method: 'POST',
        body: JSON.stringify({
          email: form.get('email'),
          password: form.get('password'),
          displayName: form.get('displayName'),
          tenantType: form.get('tenantType'),
          tenantId: form.get('tenantId'),
          districts: String(form.get('districts'))
            .split(',')
            .map((district) => district.trim())
            .filter(Boolean),
        }),
      });
      setMessage('Tenant administrator created. Share the temporary password securely.');
      formElement.reset();
      const result = await api<{ admins: TenantAdmin[] }>('admin/tenant-admins');
      setTenantAdmins(result.admins);
    } catch (submitError) {
      setError(
        submitError instanceof Error ? submitError.message : 'Account could not be created.',
      );
    }
  }

  async function submitProvider(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const formElement = event.currentTarget;
    const form = new FormData(formElement);
    try {
      const result = await api<Provider>('admin/providers', {
        method: 'POST',
        body: JSON.stringify({
          id: form.get('providerId'),
          name: form.get('providerName'),
          category: form.get('providerCategory'),
          districts: String(form.get('providerDistricts'))
            .split(',')
            .map((district) => district.trim())
            .filter(Boolean),
          code: form.get('providerCode'),
          contactPhone: form.get('providerPhone'),
          peakHours: form.get('providerPeakHours') || undefined,
          supplyWindow: form.get('providerSupplyWindow') || undefined,
          reason: form.get('providerReason'),
        }),
      });
      setMessage(`${result.name} added to the provider directory.`);
      formElement.reset();
      const updated = await api<{ providers: Provider[] }>('admin/providers');
      setProviders(updated.providers);
    } catch (submitError) {
      setError(
        submitError instanceof Error ? submitError.message : 'Provider could not be created.',
      );
    }
  }

  async function deactivateTenantAdmin(adminId: string) {
    try {
      await api<{ success: boolean }>(`admin/tenant-admins/${adminId}/deactivate`, {
        method: 'POST',
      });
      setMessage('Tenant administrator access revoked.');
      const result = await api<{ admins: TenantAdmin[] }>('admin/tenant-admins');
      setTenantAdmins(result.admins);
      const auditData = await api<{ items: AuditItem[] }>('admin/audit');
      setAudit(auditData.items);
    } catch (revokeError) {
      setError(revokeError instanceof Error ? revokeError.message : 'Access could not be revoked.');
    }
  }

  async function toggleSchedule(schedule: Schedule) {
    try {
      await api<Schedule>(`waste/admin/schedules/${schedule.id}`, {
        method: 'PUT',
        body: JSON.stringify({
          district: schedule.district,
          ward: schedule.ward,
          wasteType: schedule.wasteType,
          pickupWeekdays: schedule.pickupWeekdays,
          collectionWindow: schedule.collectionWindow,
          effectiveFrom: schedule.effectiveFrom,
          effectiveTo: schedule.effectiveTo,
          notes: schedule.notes ?? '',
          isActive: !schedule.isActive,
          reason: schedule.isActive
            ? 'Temporarily paused by city operator'
            : 'Reactivated by city operator',
        }),
      });
      setMessage(schedule.isActive ? 'Schedule paused.' : 'Schedule reactivated.');
      await load();
    } catch (toggleError) {
      setError(
        toggleError instanceof Error ? toggleError.message : 'Schedule could not be updated.',
      );
    }
  }

  if (loading)
    return (
      <main className="operator-shell">
        <p className="operator-muted">Loading secure operator console…</p>
      </main>
    );
  if (!identity) {
    return (
      <main className="operator-shell operator-login">
        <div className="operator-brand">
          URJA <span>OPERATIONS</span>
        </div>
        <section className="operator-card">
          <div className="operator-eyebrow">Protected workspace</div>
          <h1>Operator sign in</h1>
          <p>Use your platform, city, or utility-provider administrator account.</p>
          <form onSubmit={login}>
            <label>
              Username or email
              <input name="username" type="text" autoComplete="username" required />
            </label>
            <label>
              Password
              <input name="password" type="password" autoComplete="current-password" required />
            </label>
            <button className="operator-button" type="submit">
              Sign in securely
            </button>
          </form>
          {error && <div className="operator-error">{error}</div>}
        </section>
      </main>
    );
  }

  return (
    <main className="operator-shell">
      <header className="operator-header">
        <div>
          <div className="operator-brand">
            URJA <span>OPERATIONS</span>
          </div>
          <p>
            {tenantOverview
              ? `Assigned service area: ${tenantOverview.scopeLabel}`
              : 'Trusted service, useful reminders, clear audit trails.'}
          </p>
        </div>
        <button className="operator-button operator-button-light" onClick={logout}>
          Sign out
        </button>
      </header>
      {error && <div className="operator-error">{error}</div>}
      {message && <div className="operator-notice">{message}</div>}
      <section className="operator-summary">
        <div>
          <small>ACCESS ROLE</small>
          <strong>{identity.role.replace('_', ' ')}</strong>
        </div>
        <div>
          <small>ORGANIZATION</small>
          <strong>{identity.tenantId ?? 'Platform'}</strong>
        </div>
        {tenantOverview && (
          <div>
            <small>IN-SCOPE CITIZENS</small>
            <strong>{tenantOverview.activeCitizens}</strong>
          </div>
        )}
        {tenantOverview && (
          <div>
            <small>CAMPAIGN OPT-INS</small>
            <strong>{tenantOverview.campaignOptIns}</strong>
          </div>
        )}
        <div>
          <small>CAMPAIGNS</small>
          <strong>{campaigns.length}</strong>
        </div>
        {identity.role === 'CITY_ADMIN' && (
          <div>
            <small>WASTE OPT-INS</small>
            <strong>{tenantOverview?.wasteReminderOptIns ?? 0}</strong>
          </div>
        )}
        {identity.role === 'CITY_ADMIN' && (
          <div>
            <small>ACTIVE SCHEDULES</small>
            <strong>{schedules.filter((schedule) => schedule.isActive).length}</strong>
          </div>
        )}
      </section>

      {identity.role === 'ADMIN' && platformKpis && (
        <section className="operator-card operator-wide operator-analytics">
          <div className="operator-eyebrow">Platform overview · live database aggregates</div>
          <h2>Community impact dashboard</h2>
          <div className="operator-kpi-grid">
            <div>
              <small>REGISTERED CITIZENS</small>
              <strong>{platformKpis.totalRegisteredCitizens.toLocaleString()}</strong>
            </div>
            <div>
              <small>GREEN COINS</small>
              <strong>{platformKpis.totalCoinsInCirculation.toLocaleString()}</strong>
            </div>
            <div>
              <small>VERIFIED CO₂e SAVED</small>
              <strong>
                {platformKpis.totalCo2eSavedKg == null
                  ? 'Not measured'
                  : `${platformKpis.totalCo2eSavedKg.toLocaleString()} kg`}
              </strong>
            </div>
            <div>
              <small>ESTIMATED COMMUTE CO₂e</small>
              <strong>
                {platformKpis.estimatedCommuteCo2eKg == null
                  ? 'Suppressed'
                  : `${platformKpis.estimatedCommuteCo2eKg.toLocaleString()} kg`}
              </strong>
            </div>
          </div>
          <div className="operator-chart-heading">
            <div>
              <div className="operator-eyebrow">Opt-in household insights</div>
              <p>Anonymous totals from citizens who chose to share</p>
            </div>
            <span>AGGREGATED ONLY</span>
          </div>
          <div className="operator-kpi-grid operator-household-grid">
            <div>
              <small>CONSENTED CITIZENS</small>
              <strong>
                {platformKpis.householdAnalytics.consentedCitizens?.toLocaleString() ??
                  'Suppressed'}
              </strong>
            </div>
            <div>
              <small>REGISTERED DEVICES</small>
              <strong>
                {platformKpis.householdAnalytics.registeredDevices?.toLocaleString() ??
                  'Suppressed'}
              </strong>
            </div>
            <div>
              <small>ESTIMATED DEVICE ENERGY</small>
              <strong>
                {platformKpis.householdAnalytics.estimatedEnergyKwh == null
                  ? 'Suppressed'
                  : `${platformKpis.householdAnalytics.estimatedEnergyKwh.toLocaleString()} kWh`}
              </strong>
            </div>
            <div>
              <small>UTILITY READINGS</small>
              <strong>
                {platformKpis.householdAnalytics.utilityReadings?.toLocaleString() ?? 'Suppressed'}
              </strong>
            </div>
            <div>
              <small>DEVICE RUNTIME LOGS</small>
              <strong>
                {platformKpis.householdAnalytics.runtimeLogs?.toLocaleString() ?? 'Suppressed'}
              </strong>
            </div>
            <div>
              <small>CONFIRMED TRIP LOGS</small>
              <strong>
                {platformKpis.householdAnalytics.confirmedTrips?.toLocaleString() ?? 'Suppressed'}
              </strong>
            </div>
          </div>
          <p className="operator-data-note">
            Household and usage metrics include only citizens who opted into anonymous analytics and
            are suppressed below five contributors. Runtime energy is estimated from user-entered
            hours and device ratings; utility records are user-entered, not live meters. Logged
            activity is not automatically credited as CO₂e savings.
          </p>
          <div className="operator-chart-heading">
            <div>
              <div className="operator-eyebrow">City participation</div>
              <p>Registered citizens by profile district</p>
            </div>
            <span>PROFILE COUNTS</span>
          </div>
          {Object.keys(platformKpis.districtBreakdown).length === 0 ? (
            <p className="operator-muted">
              District participation will appear as citizens complete their profiles.
            </p>
          ) : (
            <div
              className="operator-district-chart"
              role="img"
              aria-label="Registered citizens by district"
            >
              {Object.entries(platformKpis.districtBreakdown)
                .sort((left, right) => right[1] - left[1])
                .slice(0, 8)
                .map(([district, count]) => {
                  const max = Math.max(...Object.values(platformKpis.districtBreakdown));
                  return (
                    <div className="operator-district-row" key={district}>
                      <span>{district}</span>
                      <div className="operator-bar-track">
                        <div
                          className="operator-bar-3d"
                          style={{ width: `${Math.max(4, (count / max) * 100)}%` }}
                        />
                      </div>
                      <strong>{count}</strong>
                    </div>
                  );
                })}
            </div>
          )}
          <div className="operator-chart-heading operator-chart-spaced">
            <div>
              <div className="operator-eyebrow">Ward participation leaderboard</div>
              <p>Largest wards with at least five registered citizens</p>
            </div>
            <span>AGGREGATED</span>
          </div>
          {platformKpis.wardBreakdown.length === 0 ? (
            <p className="operator-muted">
              Ward rankings will appear when at least five citizens have completed profiles in a
              ward.
            </p>
          ) : (
            <div
              className="operator-district-chart"
              role="img"
              aria-label="Ward participation leaderboard"
            >
              {platformKpis.wardBreakdown.slice(0, 10).map((entry, index) => {
                const max = Math.max(
                  ...platformKpis.wardBreakdown.map((ward) => ward.citizenCount),
                );
                return (
                  <div
                    className="operator-district-row operator-ward-row"
                    key={`${entry.district}-${entry.ward}`}
                  >
                    <span>
                      <b>{index + 1}.</b> {entry.district} · {entry.ward}
                    </span>
                    <div className="operator-bar-track">
                      <div
                        className="operator-bar-3d"
                        style={{ width: `${Math.max(4, (entry.citizenCount / max) * 100)}%` }}
                      />
                    </div>
                    <strong>{entry.citizenCount}</strong>
                  </div>
                );
              })}
            </div>
          )}
          <div className="operator-chart-heading operator-chart-spaced">
            <div>
              <div className="operator-eyebrow">Utility readings by area</div>
              <p>
                Average latest user-entered reading recorded in each month; units and billed periods
                stay separate
              </p>
            </div>
            <span>OPT-IN · N ≥ 5</span>
          </div>
          <div className="operator-utility-grid">
            {(Object.keys(utilityLabels) as Array<keyof typeof utilityLabels>).map((utility) => {
              const rows = platformKpis.utilityUsage
                .filter((entry) => entry.utility === utility)
                .slice(0, 10);
              const max = Math.max(1, ...rows.map((entry) => entry.averageValue));
              return (
                <article className="operator-utility-card" key={utility}>
                  <div className="operator-utility-title">
                    <strong>{utilityLabels[utility]}</strong>
                    <span>
                      {rows.length ? `${rows[0]?.unit ?? ''} · latest periods` : 'No eligible data'}
                    </span>
                  </div>
                  {rows.length === 0 ? (
                    <p className="operator-muted">
                      No opt-in area/month group has five matching readings yet.
                    </p>
                  ) : (
                    rows.map((entry) => (
                      <div
                        className="operator-usage-row"
                        key={`${entry.district}-${entry.ward}-${entry.period}-${entry.unit}`}
                      >
                        <div>
                          <strong>
                            {entry.district} · {entry.ward}
                          </strong>
                          <small>
                            {entry.period} · avg of {entry.contributors} citizens · {entry.unit}
                          </small>
                        </div>
                        <div className="operator-usage-value">
                          {entry.averageValue.toLocaleString(undefined, {
                            maximumFractionDigits: 1,
                          })}
                        </div>
                        <div className="operator-bar-track">
                          <div
                            className="operator-bar-3d"
                            style={{ width: `${Math.max(4, (entry.averageValue / max) * 100)}%` }}
                          />
                        </div>
                      </div>
                    ))
                  )}
                </article>
              );
            })}
          </div>
          <div className="operator-chart-heading operator-chart-spaced">
            <div>
              <div className="operator-eyebrow">Low-carbon commute estimates</div>
              <p>
                Illustrative per-kilometre estimates from citizens’ confirmed walking, cycling, or
                transit logs; not verified savings
              </p>
            </div>
            <span>OPT-IN · N ≥ 5</span>
          </div>
          {platformKpis.estimatedImpactByArea.length === 0 ? (
            <p className="operator-muted">
              No area has five opt-in contributors with estimated commute records yet.
            </p>
          ) : (
            <div
              className="operator-district-chart"
              role="img"
              aria-label="Estimated commute carbon impact by ward"
            >
              {platformKpis.estimatedImpactByArea.slice(0, 10).map((entry, index) => {
                const max = Math.max(
                  ...platformKpis.estimatedImpactByArea.map((area) => area.estimatedCo2eKg),
                );
                return (
                  <div
                    className="operator-district-row operator-ward-row"
                    key={`${entry.district}-${entry.ward}`}
                  >
                    <span>
                      <b>{index + 1}.</b> {entry.district} · {entry.ward}
                    </span>
                    <div className="operator-bar-track">
                      <div
                        className="operator-bar-3d"
                        style={{ width: `${Math.max(4, (entry.estimatedCo2eKg / max) * 100)}%` }}
                      />
                    </div>
                    <strong>
                      {entry.estimatedCo2eKg.toLocaleString(undefined, {
                        maximumFractionDigits: 1,
                      })}
                    </strong>
                  </div>
                );
              })}
            </div>
          )}
          {Object.keys(platformKpis.providerSubscribers ?? {}).length > 0 && (
            <>
              <div className="operator-chart-heading operator-chart-spaced">
                <div>
                  <div className="operator-eyebrow">Linked provider leaderboard</div>
                  <p>Anonymous household-analytics opt-ins linked to each service provider</p>
                </div>
                <span>AGGREGATED · N ≥ 5</span>
              </div>
              <div className="operator-district-chart">
                {Object.entries(platformKpis.providerSubscribers ?? {})
                  .sort((a, b) => b[1] - a[1])
                  .slice(0, 8)
                  .map(([providerId, count]) => (
                    <div className="operator-district-row" key={providerId}>
                      <span>{providerId}</span>
                      <div className="operator-bar-track">
                        <div
                          className="operator-bar-3d"
                          style={{
                            width: `${Math.max(4, (count / Math.max(...Object.values(platformKpis.providerSubscribers ?? {}))) * 100)}%`,
                          }}
                        />
                      </div>
                      <strong>{count}</strong>
                    </div>
                  ))}
              </div>
            </>
          )}
          {platformKpis.totalCo2eSavedKg == null && (
            <p className="operator-data-note">
              CO₂e saved is not yet measurable from these records. Utility consumption and
              self-reported actions are not savings by themselves; a validated baseline and approved
              emissions factors are needed before crediting reductions.
            </p>
          )}
        </section>
      )}

      <div className="operator-grid">
        <section className="operator-card">
          <div className="operator-eyebrow">Consent-first communication</div>
          <h2>Create a campaign</h2>
          <p>
            Recipients are restricted to your organization and campaign opt-ins. Choose a district,
            optional ward, or linked provider. The console reports the eligible and delivered
            counts; it never bypasses a citizen’s notification preference.
          </p>
          <form onSubmit={submitCampaign}>
            <label>
              Title
              <input name="title" minLength={3} maxLength={120} required />
            </label>
            <label>
              Message
              <textarea name="message" minLength={5} maxLength={500} required />
            </label>
            <label>
              {identity.role === 'ADMIN' ? 'City / district (optional)' : 'City / district'}
              <input name="district" placeholder="Ahmedabad" required={identity.role !== 'ADMIN'} />
            </label>
            <label>
              Ward (optional; requires a district)
              <input name="ward" placeholder="Ward 12" />
            </label>
            {identity.role === 'ADMIN' && (
              <label>
                Provider audience (optional)
                <select name="targetProviderId" defaultValue="">
                  <option value="">All linked providers</option>
                  {providers.map((provider) => (
                    <option value={provider.id} key={provider.id}>
                      {provider.name} · {provider.category}
                    </option>
                  ))}
                </select>
              </label>
            )}
            <label>
              Category
              <select name="category" defaultValue="ALERT">
                <option>ALERT</option>
                <option>COMMUNITY</option>
                <option>HABIT</option>
              </select>
            </label>
            <label>
              Schedule for (optional)
              <input name="scheduledAt" type="datetime-local" />
            </label>
            <label>
              Reason for audit
              <input name="reason" minLength={5} maxLength={240} required />
            </label>
            <button className="operator-button" type="submit">
              Save campaign
            </button>
          </form>
        </section>

        {identity.role === 'CITY_ADMIN' && (
          <section className="operator-card">
            <div className="operator-eyebrow">Municipal services</div>
            <h2>Waste collection schedule</h2>
            <p>
              Weekday numbers use Sunday = 0 through Saturday = 6. Overlapping active schedules are
              rejected.
            </p>
            <form onSubmit={submitSchedule}>
              <label>
                District
                <input name="district" required />
              </label>
              <label>
                Ward / locality
                <input name="ward" required />
              </label>
              <label>
                Waste stream
                <select name="wasteType">
                  <option>ORGANIC</option>
                  <option>DRY_RECYCLABLE</option>
                  <option>RESIDUAL</option>
                  <option>SPECIAL_HANDLING</option>
                </select>
              </label>
              <label>
                Pickup weekdays
                <input name="weekdays" placeholder="1,3,5" required />
              </label>
              <label>
                Collection window
                <input name="collectionWindow" placeholder="06:00–08:00" required />
              </label>
              <label>
                Effective from
                <input name="effectiveFrom" type="date" defaultValue={localDate} required />
              </label>
              <label>
                Effective to (optional)
                <input name="effectiveTo" type="date" />
              </label>
              <label>
                Public notes
                <textarea name="notes" maxLength={500} />
              </label>
              <label>
                Reason for audit
                <input name="reason" minLength={5} maxLength={240} required />
              </label>
              <button className="operator-button" type="submit">
                Publish schedule
              </button>
            </form>
          </section>
        )}

        {identity.role === 'ADMIN' && (
          <section className="operator-card">
            <div className="operator-eyebrow">Access management</div>
            <h2>Provision tenant admin</h2>
            <p>
              Provider tenants must match the provider directory. District access is explicitly
              assigned.
            </p>
            <form onSubmit={submitTenantAdmin}>
              <label>
                Display name
                <input name="displayName" minLength={2} required />
              </label>
              <label>
                Email
                <input name="email" type="email" required />
              </label>
              <label>
                Initial password
                <input name="password" type="password" minLength={12} required />
              </label>
              <label>
                Organization type
                <select name="tenantType">
                  <option>PROVIDER</option>
                  <option>CITY</option>
                </select>
              </label>
              <label>
                Tenant ID
                <input name="tenantId" placeholder="torrent_power or amc" required />
              </label>
              <label>
                Allowed districts (comma separated)
                <input name="districts" placeholder="Ahmedabad, Gandhinagar" required />
              </label>
              <button className="operator-button" type="submit">
                Create account
              </button>
            </form>
          </section>
        )}

        {identity.role === 'ADMIN' && (
          <section className="operator-card">
            <div className="operator-eyebrow">Utility directory</div>
            <h2>Add a service provider</h2>
            <p>
              New providers are stored in the shared directory and become available to citizen
              accounts and provider-admin provisioning.
            </p>
            <form onSubmit={submitProvider}>
              <label>
                Provider ID
                <input
                  name="providerId"
                  pattern="[a-z0-9][a-z0-9_-]*"
                  placeholder="surat_solar"
                  required
                />
              </label>
              <label>
                Organization name
                <input name="providerName" minLength={2} maxLength={120} required />
              </label>
              <label>
                Service category
                <select name="providerCategory">
                  <option>ELECTRICITY</option>
                  <option>GAS</option>
                  <option>WATER</option>
                  <option>TRANSIT</option>
                </select>
              </label>
              <label>
                Official code
                <input name="providerCode" minLength={2} required />
              </label>
              <label>
                Contact phone
                <input name="providerPhone" minLength={3} required />
              </label>
              <label>
                Districts served (comma separated)
                <input name="providerDistricts" placeholder="Surat, Navsari" required />
              </label>
              <label>
                Peak hours (optional)
                <input name="providerPeakHours" placeholder="18:00–21:00" />
              </label>
              <label>
                Water supply window (optional)
                <input name="providerSupplyWindow" placeholder="06:00–08:00" />
              </label>
              <label>
                Reason for audit
                <input name="providerReason" minLength={5} maxLength={240} required />
              </label>
              <button className="operator-button" type="submit">
                Add provider
              </button>
            </form>
          </section>
        )}

        {identity.role === 'ADMIN' && (
          <section className="operator-card">
            <div className="operator-eyebrow">Active directory • {providers.length} providers</div>
            <h2>Service providers</h2>
            {providers.slice(0, 12).map((provider) => (
              <div className="operator-row" key={provider.id}>
                <div>
                  <strong>{provider.name}</strong>
                  <small>
                    {provider.category} · {provider.districts.join(', ')}
                  </small>
                </div>
                <span>{provider.status ?? 'ACTIVE'}</span>
              </div>
            ))}
          </section>
        )}

        <section className="operator-card">
          <div className="operator-eyebrow">Delivery tracking</div>
          <h2>Recent campaigns</h2>
          {campaigns.length === 0 ? (
            <p className="operator-muted">No campaigns have been created.</p>
          ) : (
            campaigns.map((campaign) => (
              <article className="operator-row" key={campaign.id}>
                <div>
                  <strong>{campaign.title}</strong>
                  <small>
                    {campaign.category} · {campaign.targetDistrict ?? 'All districts'}
                    {campaign.targetWard ? ` · Ward ${campaign.targetWard}` : ''}
                    {campaign.targetProviderId
                      ? ` · Provider ${campaign.targetProviderId}`
                      : ''} · {campaign.status} · {new Date(campaign.scheduledAt).toLocaleString()}
                  </small>
                </div>
                <span>
                  {campaign.deliveredCount}/{campaign.recipientCount}
                </span>
              </article>
            ))
          )}
        </section>

        {identity.role === 'CITY_ADMIN' && (
          <section className="operator-card">
            <div className="operator-eyebrow">Effective-dated records</div>
            <h2>Published schedules</h2>
            {schedules.length === 0 ? (
              <p className="operator-muted">No schedules published yet.</p>
            ) : (
              schedules.map((schedule) => (
                <article className="operator-row" key={schedule.id}>
                  <div>
                    <strong>
                      {schedule.district} · Ward {schedule.ward}
                    </strong>
                    <small>
                      {schedule.wasteType} ·{' '}
                      {schedule.pickupWeekdays.map((day) => weekdays[day]).join(', ')} ·{' '}
                      {schedule.collectionWindow}
                    </small>
                  </div>
                  <button className="operator-chip" onClick={() => void toggleSchedule(schedule)}>
                    {schedule.isActive ? 'Pause' : 'Reactivate'}
                  </button>
                </article>
              ))
            )}
          </section>
        )}

        {identity.role === 'ADMIN' && (
          <section className="operator-card">
            <div className="operator-eyebrow">Organizations</div>
            <h2>Tenant administrators</h2>
            {tenantAdmins.map((account) => (
              <article className="operator-row" key={account.id}>
                <div>
                  <strong>{account.displayName}</strong>
                  <small>
                    {account.email} · {account.tenantType} / {account.tenantId}
                  </small>
                </div>
                <button
                  className="operator-chip operator-chip-danger"
                  onClick={() => void deactivateTenantAdmin(account.id)}
                >
                  Revoke
                </button>
              </article>
            ))}
          </section>
        )}

        <section className="operator-card operator-wide">
          <div className="operator-eyebrow">Immutable history</div>
          <h2>Recent administrative actions</h2>
          {audit.length === 0 ? (
            <p className="operator-muted">No audited actions yet.</p>
          ) : (
            audit.map((entry) => (
              <article className="operator-row" key={entry.id}>
                <div>
                  <strong>{entry.action.replaceAll('_', ' ')}</strong>
                  <small>
                    {entry.actorEmail} · {entry.resourceType} ·{' '}
                    {entry.reason ?? 'No reason recorded'}
                  </small>
                </div>
                <span>{new Date(entry.createdAt).toLocaleString()}</span>
              </article>
            ))
          )}
        </section>
      </div>
    </main>
  );
}
