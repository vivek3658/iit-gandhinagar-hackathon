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
  providerSubscribers: Record<string, number> | null;
};
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
  const result = await response.json() as ApiResult<T>;
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
      const tenant = await api<OperatorIdentity & { displayName: string; districts: string[] }>('admin/tenant/me');
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
        setMessage(`Platform data ready: ${adminData.kpis.totalRegisteredCitizens} citizens, ${adminData.kpis.totalCoinsInCirculation} coins.`);
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

  useEffect(() => { void load(); }, [load]);

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
      const result = await response.json() as { message?: string };
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
          scheduledAt: form.get('scheduledAt')
            ? new Date(String(form.get('scheduledAt'))).toISOString()
            : undefined,
          reason: form.get('reason'),
        }),
      });
      setMessage(`Campaign saved for ${result.recipientCount} opted-in recipients.`);
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
      pickupWeekdays: String(form.get('weekdays')).split(',').map((day) => Number(day.trim())).filter(Number.isInteger),
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
          districts: String(form.get('districts')).split(',').map((district) => district.trim()).filter(Boolean),
        }),
      });
      setMessage('Tenant administrator created. Share the temporary password securely.');
      formElement.reset();
      const result = await api<{ admins: TenantAdmin[] }>('admin/tenant-admins');
      setTenantAdmins(result.admins);
    } catch (submitError) {
      setError(submitError instanceof Error ? submitError.message : 'Account could not be created.');
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
      setError(submitError instanceof Error ? submitError.message : 'Provider could not be created.');
    }
  }

  async function deactivateTenantAdmin(adminId: string) {
    try {
      await api<{ success: boolean }>(`admin/tenant-admins/${adminId}/deactivate`, { method: 'POST' });
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
          reason: schedule.isActive ? 'Temporarily paused by city operator' : 'Reactivated by city operator',
        }),
      });
      setMessage(schedule.isActive ? 'Schedule paused.' : 'Schedule reactivated.');
      await load();
    } catch (toggleError) {
      setError(toggleError instanceof Error ? toggleError.message : 'Schedule could not be updated.');
    }
  }

  if (loading) return <main className="operator-shell"><p className="operator-muted">Loading secure operator console…</p></main>;
  if (!identity) {
    return (
      <main className="operator-shell operator-login">
        <div className="operator-brand">URJA <span>OPERATIONS</span></div>
        <section className="operator-card">
          <div className="operator-eyebrow">Protected workspace</div>
          <h1>Operator sign in</h1>
          <p>Use your platform, city, or utility-provider administrator account.</p>
          <form onSubmit={login}>
            <label>Username or email<input name="username" type="text" autoComplete="username" required /></label>
            <label>Password<input name="password" type="password" autoComplete="current-password" required /></label>
            <button className="operator-button" type="submit">Sign in securely</button>
          </form>
          {error && <div className="operator-error">{error}</div>}
        </section>
      </main>
    );
  }

  return (
    <main className="operator-shell">
      <header className="operator-header">
        <div><div className="operator-brand">URJA <span>OPERATIONS</span></div><p>{tenantOverview ? `Assigned service area: ${tenantOverview.scopeLabel}` : 'Trusted service, useful reminders, clear audit trails.'}</p></div>
        <button className="operator-button operator-button-light" onClick={logout}>Sign out</button>
      </header>
      {error && <div className="operator-error">{error}</div>}
      {message && <div className="operator-notice">{message}</div>}
      <section className="operator-summary">
        <div><small>ACCESS ROLE</small><strong>{identity.role.replace('_', ' ')}</strong></div>
        <div><small>ORGANIZATION</small><strong>{identity.tenantId ?? 'Platform'}</strong></div>
        {tenantOverview && <div><small>IN-SCOPE CITIZENS</small><strong>{tenantOverview.activeCitizens}</strong></div>}
        {tenantOverview && <div><small>CAMPAIGN OPT-INS</small><strong>{tenantOverview.campaignOptIns}</strong></div>}
        <div><small>CAMPAIGNS</small><strong>{campaigns.length}</strong></div>
        {identity.role === 'CITY_ADMIN' && <div><small>WASTE OPT-INS</small><strong>{tenantOverview?.wasteReminderOptIns ?? 0}</strong></div>}
        {identity.role === 'CITY_ADMIN' && <div><small>ACTIVE SCHEDULES</small><strong>{schedules.filter((schedule) => schedule.isActive).length}</strong></div>}
      </section>

      {identity.role === 'ADMIN' && platformKpis && (
        <section className="operator-card operator-wide operator-analytics">
          <div className="operator-eyebrow">Platform impact • live directory metrics</div>
          <h2>Community at a glance</h2>
          <div className="operator-kpi-grid">
            <div><small>REGISTERED CITIZENS</small><strong>{platformKpis.totalRegisteredCitizens.toLocaleString()}</strong></div>
            <div><small>GREEN COINS</small><strong>{platformKpis.totalCoinsInCirculation.toLocaleString()}</strong></div>
            <div><small>CO₂e SAVED</small><strong>{platformKpis.totalCo2eSavedKg == null ? 'Not measured' : `${platformKpis.totalCo2eSavedKg.toLocaleString()} kg`}</strong></div>
          </div>
          <div className="operator-chart-heading">
            <div><div className="operator-eyebrow">Participation by district</div><p>Registered citizens by profile district</p></div>
            <span>LIVE PROFILE DATA</span>
          </div>
          {Object.keys(platformKpis.districtBreakdown).length === 0 ? (
            <p className="operator-muted">District participation will appear as citizens complete their profiles.</p>
          ) : (
            <div className="operator-district-chart" role="img" aria-label="Registered citizens by district">
              {Object.entries(platformKpis.districtBreakdown)
                .sort((left, right) => right[1] - left[1])
                .slice(0, 8)
                .map(([district, count]) => {
                  const max = Math.max(...Object.values(platformKpis.districtBreakdown));
                  return (
                    <div className="operator-district-row" key={district}>
                      <span>{district}</span>
                      <div className="operator-bar-track">
                        <div className="operator-bar-3d" style={{ width: `${Math.max(4, (count / max) * 100)}%` }} />
                      </div>
                      <strong>{count}</strong>
                    </div>
                  );
                })}
            </div>
          )}
          {platformKpis.totalCo2eSavedKg == null && (
            <p className="operator-data-note">CO₂e is shown as unavailable until verified emissions data is connected; no estimated totals are substituted.</p>
          )}
        </section>
      )}

      <div className="operator-grid">
        <section className="operator-card">
          <div className="operator-eyebrow">Consent-first communication</div>
          <h2>Create a campaign</h2>
          <p>Recipients are restricted to your organization and the matching opt-in. Scheduled notices are delivered to the in-app inbox.</p>
          <form onSubmit={submitCampaign}>
            <label>Title<input name="title" minLength={3} maxLength={120} required /></label>
            <label>Message<textarea name="message" minLength={5} maxLength={500} required /></label>
            {identity.role === 'ADMIN' && <label>District (optional)<input name="district" placeholder="Ahmedabad" /></label>}
            {identity.role !== 'ADMIN' && <label>District<input name="district" placeholder="Ahmedabad" required /></label>}
            <label>Category<select name="category" defaultValue="ALERT"><option>ALERT</option><option>COMMUNITY</option><option>HABIT</option></select></label>
            <label>Schedule for (optional)<input name="scheduledAt" type="datetime-local" /></label>
            <label>Reason for audit<input name="reason" minLength={5} maxLength={240} required /></label>
            <button className="operator-button" type="submit">Save campaign</button>
          </form>
        </section>

        {identity.role === 'CITY_ADMIN' && (
          <section className="operator-card">
            <div className="operator-eyebrow">Municipal services</div>
            <h2>Waste collection schedule</h2>
            <p>Weekday numbers use Sunday = 0 through Saturday = 6. Overlapping active schedules are rejected.</p>
            <form onSubmit={submitSchedule}>
              <label>District<input name="district" required /></label>
              <label>Ward / locality<input name="ward" required /></label>
              <label>Waste stream<select name="wasteType"><option>ORGANIC</option><option>DRY_RECYCLABLE</option><option>RESIDUAL</option><option>SPECIAL_HANDLING</option></select></label>
              <label>Pickup weekdays<input name="weekdays" placeholder="1,3,5" required /></label>
              <label>Collection window<input name="collectionWindow" placeholder="06:00–08:00" required /></label>
              <label>Effective from<input name="effectiveFrom" type="date" defaultValue={localDate} required /></label>
              <label>Effective to (optional)<input name="effectiveTo" type="date" /></label>
              <label>Public notes<textarea name="notes" maxLength={500} /></label>
              <label>Reason for audit<input name="reason" minLength={5} maxLength={240} required /></label>
              <button className="operator-button" type="submit">Publish schedule</button>
            </form>
          </section>
        )}

        {identity.role === 'ADMIN' && (
          <section className="operator-card">
            <div className="operator-eyebrow">Access management</div>
            <h2>Provision tenant admin</h2>
            <p>Provider tenants must match the provider directory. District access is explicitly assigned.</p>
            <form onSubmit={submitTenantAdmin}>
              <label>Display name<input name="displayName" minLength={2} required /></label>
              <label>Email<input name="email" type="email" required /></label>
              <label>Initial password<input name="password" type="password" minLength={12} required /></label>
              <label>Organization type<select name="tenantType"><option>PROVIDER</option><option>CITY</option></select></label>
              <label>Tenant ID<input name="tenantId" placeholder="torrent_power or amc" required /></label>
              <label>Allowed districts (comma separated)<input name="districts" placeholder="Ahmedabad, Gandhinagar" required /></label>
              <button className="operator-button" type="submit">Create account</button>
            </form>
          </section>
        )}

        {identity.role === 'ADMIN' && (
          <section className="operator-card">
            <div className="operator-eyebrow">Utility directory</div>
            <h2>Add a service provider</h2>
            <p>New providers are stored in the shared directory and become available to citizen accounts and provider-admin provisioning.</p>
            <form onSubmit={submitProvider}>
              <label>Provider ID<input name="providerId" pattern="[a-z0-9][a-z0-9_-]*" placeholder="surat_solar" required /></label>
              <label>Organization name<input name="providerName" minLength={2} maxLength={120} required /></label>
              <label>Service category<select name="providerCategory"><option>ELECTRICITY</option><option>GAS</option><option>WATER</option><option>TRANSIT</option></select></label>
              <label>Official code<input name="providerCode" minLength={2} required /></label>
              <label>Contact phone<input name="providerPhone" minLength={3} required /></label>
              <label>Districts served (comma separated)<input name="providerDistricts" placeholder="Surat, Navsari" required /></label>
              <label>Peak hours (optional)<input name="providerPeakHours" placeholder="18:00–21:00" /></label>
              <label>Water supply window (optional)<input name="providerSupplyWindow" placeholder="06:00–08:00" /></label>
              <label>Reason for audit<input name="providerReason" minLength={5} maxLength={240} required /></label>
              <button className="operator-button" type="submit">Add provider</button>
            </form>
          </section>
        )}

        {identity.role === 'ADMIN' && (
          <section className="operator-card">
            <div className="operator-eyebrow">Active directory • {providers.length} providers</div>
            <h2>Service providers</h2>
            {providers.slice(0, 12).map((provider) => (
              <div className="operator-row" key={provider.id}>
                <div><strong>{provider.name}</strong><small>{provider.category} · {provider.districts.join(', ')}</small></div>
                <span>{provider.status ?? 'ACTIVE'}</span>
              </div>
            ))}
          </section>
        )}

        <section className="operator-card">
          <div className="operator-eyebrow">Delivery tracking</div>
          <h2>Recent campaigns</h2>
          {campaigns.length === 0 ? <p className="operator-muted">No campaigns have been created.</p> : campaigns.map((campaign) => (
            <article className="operator-row" key={campaign.id}>
              <div><strong>{campaign.title}</strong><small>{campaign.category} · {campaign.status} · {new Date(campaign.scheduledAt).toLocaleString()}</small></div>
              <span>{campaign.deliveredCount}/{campaign.recipientCount}</span>
            </article>
          ))}
        </section>

        {identity.role === 'CITY_ADMIN' && (
          <section className="operator-card">
            <div className="operator-eyebrow">Effective-dated records</div>
            <h2>Published schedules</h2>
            {schedules.length === 0 ? <p className="operator-muted">No schedules published yet.</p> : schedules.map((schedule) => (
              <article className="operator-row" key={schedule.id}>
                <div><strong>{schedule.district} · Ward {schedule.ward}</strong><small>{schedule.wasteType} · {schedule.pickupWeekdays.map((day) => weekdays[day]).join(', ')} · {schedule.collectionWindow}</small></div>
                <button className="operator-chip" onClick={() => void toggleSchedule(schedule)}>{schedule.isActive ? 'Pause' : 'Reactivate'}</button>
              </article>
            ))}
          </section>
        )}

        {identity.role === 'ADMIN' && (
          <section className="operator-card">
            <div className="operator-eyebrow">Organizations</div>
            <h2>Tenant administrators</h2>
            {tenantAdmins.map((account) => (
              <article className="operator-row" key={account.id}>
                <div><strong>{account.displayName}</strong><small>{account.email} · {account.tenantType} / {account.tenantId}</small></div>
                <button className="operator-chip operator-chip-danger" onClick={() => void deactivateTenantAdmin(account.id)}>Revoke</button>
              </article>
            ))}
          </section>
        )}

        <section className="operator-card operator-wide">
          <div className="operator-eyebrow">Immutable history</div>
          <h2>Recent administrative actions</h2>
          {audit.length === 0 ? <p className="operator-muted">No audited actions yet.</p> : audit.map((entry) => (
            <article className="operator-row" key={entry.id}>
              <div><strong>{entry.action.replaceAll('_', ' ')}</strong><small>{entry.actorEmail} · {entry.resourceType} · {entry.reason ?? 'No reason recorded'}</small></div>
              <span>{new Date(entry.createdAt).toLocaleString()}</span>
            </article>
          ))}
        </section>
      </div>
    </main>
  );
}
