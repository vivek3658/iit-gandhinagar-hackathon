import { Pool } from 'pg';
import fp from 'fastify-plugin';
import { AuthService } from '../modules/auth/auth.service';
import { ActivityService } from '../modules/activity/activity.service';
import { GardenService } from '../modules/garden/garden.service';
import { MascotService } from '../modules/mascot/mascot.service';
import { LeaderboardService } from '../modules/leaderboard/leaderboard.service';

declare module 'fastify' {
  interface FastifyInstance {
    db: Pool | null;
  }
}

export function parsePostgresUrl(rawUrl: string): {
  user?: string;
  password?: string;
  host: string;
  port: number;
  database: string;
  ssl?: { rejectUnauthorized: boolean };
} | null {
  if (!rawUrl) return null;
  const clean = rawUrl.trim().replace(/^["']|["']$/g, '');
  const m = clean.match(
    /^(?:postgres(?:ql)?:\/\/)(?:([^:]+)(?::(.*))?@)?([^/:?#]+)(?::(\d+))?(?:\/([^?#]*))?(?:\?(.*))?$/
  );
  if (!m) return null;

  const [, user, rawPass, host, portStr, dbName] = m;
  if (!host) return null;

  let password = rawPass;
  if (password && password.startsWith('[') && password.endsWith(']')) {
    password = password.slice(1, -1);
  }
  if (password) {
    try {
      password = decodeURIComponent(password);
    } catch {
      // Keep as-is if decodeURIComponent fails
    }
  }

  const isSsl =
    host.includes('supabase.co') ||
    host.includes('pooler.supabase.com') ||
    process.env.NODE_ENV === 'production';

  return {
    user: user ? decodeURIComponent(user) : 'postgres',
    password: password || undefined,
    host,
    port: portStr ? Number(portStr) : 5432,
    database: dbName ? decodeURIComponent(dbName) : 'postgres',
    ssl: isSsl ? { rejectUnauthorized: false } : undefined,
  };
}

export default fp(async (fastify) => {
  const config = fastify.config;

  let pool: Pool | null = null;
  const pgUrl = config?.DATABASE_URL;
  if (pgUrl && (pgUrl.startsWith('postgres://') || pgUrl.startsWith('postgresql://'))) {
    try {
      const parsedConfig = parsePostgresUrl(pgUrl);
      if (parsedConfig) {
        pool = new Pool({
          user: parsedConfig.user,
          password: parsedConfig.password,
          host: parsedConfig.host,
          port: parsedConfig.port,
          database: parsedConfig.database,
          ssl: parsedConfig.ssl,
          max: 10,
          idleTimeoutMillis: 30000,
          connectionTimeoutMillis: 5000,
        });

        pool.on('error', (err) => {
          fastify.log.warn({ err: err.message }, '[PostgreSQL] Connection warning on idle client');
        });

        const client = await pool.connect();
        client.release();
        fastify.log.info('[PostgreSQL] Connection pool established successfully');
      } else {
        throw new Error('DATABASE_URL is not a valid PostgreSQL connection string');
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      if (pool) {
        await pool.end();
        pool = null;
      }
      if (config?.NODE_ENV === 'production') {
        throw new Error(`Could not connect to PostgreSQL: ${msg}`);
      }
      fastify.log.warn({ err: msg }, '[PostgreSQL] Failed to configure pool for DATABASE_URL');
    }
  } else {
    if (config?.NODE_ENV === 'production') {
      throw new Error('DATABASE_URL must be configured in production');
    }
    fastify.log.info('[Database] No DATABASE_URL provided. Operating with in-memory stores.');
  }

  fastify.decorate('db', pool);
  ActivityService.setDbPool(pool, config?.NODE_ENV !== 'production');
  GardenService.configure(pool, config?.NODE_ENV !== 'production');
  MascotService.configure(pool, config?.NODE_ENV !== 'production');
  LeaderboardService.getInstance().setDbPool(pool);

  // Wire persistent DB clients to AuthService (isolated in-memory in tests)
  if (config?.NODE_ENV !== 'test') {
    await AuthService.setDbClients({ db: pool });
  } else {
    await AuthService.setDbClients({ db: null });
  }

  fastify.addHook('onClose', async () => {
    if (pool) {
      await pool.end().catch((err: unknown) => fastify.log.error(err, '[PostgreSQL] Error closing pool'));
    }
  });
});
