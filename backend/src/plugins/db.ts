import { Pool } from 'pg';
import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import fp from 'fastify-plugin';
import { AuthService } from '../modules/auth/auth.service';

declare module 'fastify' {
  interface FastifyInstance {
    db: Pool | null;
    supabase: SupabaseClient | null;
  }
}

export default fp(async (fastify) => {
  const config = fastify.config;

  let pool: Pool | null = null;
  let supabaseClient: SupabaseClient | null = null;

  // 1. Supabase Client Initialization (via SUPABASE_URL + API keys)
  const supabaseUrl = config?.SUPABASE_URL || (config?.DATABASE_URL?.startsWith('https://') ? config.DATABASE_URL : undefined);
  const supabaseKey = config?.SUPABASE_SERVICE_ROLE_KEY || config?.SUPABASE_ANON_KEY;

  if (supabaseUrl && supabaseKey) {
    try {
      supabaseClient = createClient(supabaseUrl, supabaseKey, {
        auth: {
          persistSession: false,
          autoRefreshToken: false,
        },
      });
      fastify.log.info({ supabaseUrl }, '[Supabase] Initialized Supabase client successfully');
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      fastify.log.error({ err: msg }, '[Supabase] Failed to initialize Supabase client');
    }
  }

  // 2. PostgreSQL Connection Pool (via DATABASE_URL or postgres-formatted SUPABASE_URL)
  let pgUrl = config?.DATABASE_URL;
  if (!pgUrl && config?.SUPABASE_URL && (config.SUPABASE_URL.startsWith('postgres://') || config.SUPABASE_URL.startsWith('postgresql://'))) {
    pgUrl = config.SUPABASE_URL;
  }

  if (pgUrl && (pgUrl.startsWith('postgres://') || pgUrl.startsWith('postgresql://'))) {
    try {
      const isSsl = pgUrl.includes('supabase.co') || pgUrl.includes('pooler.supabase.com') || config?.NODE_ENV === 'production';
      pool = new Pool({
        connectionString: pgUrl,
        ssl: isSsl ? { rejectUnauthorized: false } : undefined,
        max: 20,
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: 5000,
      });

      pool.on('error', (err) => {
        fastify.log.error({ err }, '[PostgreSQL] Unexpected error on idle client');
      });

      // Verify connection asynchronously without blocking server boot
      pool.connect()
        .then((client) => {
          fastify.log.info('[PostgreSQL] Connection pool established successfully');
          client.release();
        })
        .catch((err: unknown) => {
          const msg = err instanceof Error ? err.message : String(err);
          fastify.log.warn({ err: msg }, '[PostgreSQL] Could not establish initial connection to DATABASE_URL');
        });
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      fastify.log.warn({ err: msg }, '[PostgreSQL] Failed to configure pool for DATABASE_URL');
    }
  } else if (!supabaseClient) {
    fastify.log.info('[Database] No DATABASE_URL or SUPABASE_URL provided. Operating with in-memory stores.');
  }

  fastify.decorate('db', pool);
  fastify.decorate('supabase', supabaseClient);

  // Wire persistent DB clients to AuthService
  AuthService.setDbClients({ supabase: supabaseClient, db: pool });

  fastify.addHook('onClose', async () => {
    if (pool) {
      await pool.end().catch((err: unknown) => fastify.log.error(err, '[PostgreSQL] Error closing pool'));
    }
  });
});
