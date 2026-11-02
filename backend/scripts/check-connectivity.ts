import net from 'node:net';
import https from 'node:https';
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { Pool } from 'pg';
import { createClient } from '@supabase/supabase-js';
import Redis from 'ioredis';
import { MongoClient } from 'mongodb';
import amqp from 'amqplib';

function parseEnv(filePath: string): Record<string, string> {
  const result: Record<string, string> = {};
  if (!fs.existsSync(filePath)) return result;
  const content = fs.readFileSync(filePath, 'utf-8');
  for (const line of content.split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eqIdx = trimmed.indexOf('=');
    if (eqIdx !== -1) {
      const key = trimmed.slice(0, eqIdx).trim();
      let val = trimmed.slice(eqIdx + 1).trim();
      if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
        val = val.slice(1, -1);
      }
      result[key] = val;
    }
  }
  return result;
}

const rootEnvPath = path.resolve(process.cwd(), '../.env');
const backendEnvPath = path.resolve(process.cwd(), '.env');
const backendEnv = parseEnv(backendEnvPath);
const rootEnv = parseEnv(rootEnvPath);
const mergedEnv: Record<string, string | undefined> = { ...rootEnv, ...backendEnv, ...process.env };

// Auto-alias SUPABASE_URL to DATABASE_URL if needed
if (!mergedEnv.DATABASE_URL && mergedEnv.SUPABASE_URL) {
  mergedEnv.DATABASE_URL = mergedEnv.SUPABASE_URL;
}
if (!mergedEnv.SUPABASE_URL && mergedEnv.DATABASE_URL) {
  mergedEnv.SUPABASE_URL = mergedEnv.DATABASE_URL;
}

function mask(val: string | undefined): string {
  if (!val) return 'NOT_SET';
  if (val.length <= 8) return '****';
  return `${val.substring(0, 4)}...${val.substring(val.length - 4)}`;
}

function checkTcp(host: string, port: number, timeoutMs = 2500): Promise<{ ok: boolean; message: string; latencyMs: number }> {
  return new Promise((resolve) => {
    const start = Date.now();
    const socket = new net.Socket();
    socket.setTimeout(timeoutMs);

    socket.connect(port, host, () => {
      const latencyMs = Date.now() - start;
      socket.destroy();
      resolve({ ok: true, message: `Connected to ${host}:${port} successfully`, latencyMs });
    });

    socket.on('data', () => { socket.destroy(); });
    socket.on('error', (err: any) => {
      const latencyMs = Date.now() - start;
      socket.destroy();
      resolve({ ok: false, message: `Failed to connect to ${host}:${port} (${err.code || err.message})`, latencyMs });
    });
    socket.on('timeout', () => {
      const latencyMs = Date.now() - start;
      socket.destroy();
      resolve({ ok: false, message: `Connection to ${host}:${port} timed out after ${timeoutMs}ms`, latencyMs });
    });
  });
}

function checkHttp(urlStr: string, options: https.RequestOptions = {}, timeoutMs = 4000): Promise<{ ok: boolean; status?: number; data?: string; message: string }> {
  return new Promise((resolve) => {
    try {
      const url = new URL(urlStr);
      const isHttps = url.protocol === 'https:';
      const client = isHttps ? https : http;

      const req = client.request(url, {
        method: options.method || 'GET',
        headers: options.headers || {},
        timeout: timeoutMs,
      }, (res) => {
        let body = '';
        res.on('data', (chunk) => { body += chunk; });
        res.on('end', () => {
          resolve({
            ok: (res.statusCode || 0) >= 200 && (res.statusCode || 0) < 400,
            status: res.statusCode,
            data: body.slice(0, 200),
            message: `HTTP ${res.statusCode} ${res.statusMessage || ''}`,
          });
        });
      });

      req.on('timeout', () => {
        req.destroy();
        resolve({ ok: false, message: `Request to ${urlStr} timed out after ${timeoutMs}ms` });
      });
      req.on('error', (err: any) => {
        resolve({ ok: false, message: `HTTP request failed: ${err.message}` });
      });
      req.end();
    } catch (e: any) {
      resolve({ ok: false, message: `Invalid URL: ${e.message}` });
    }
  });
}

export async function runDiagnostics() {
  console.log('========================================================================');
  console.log('        URJA ONE BACKEND & INTEGRATION CONNECTIVITY DIAGNOSTIC         ');
  console.log('========================================================================\n');

  console.log('1. ENVIRONMENT VARIABLES AUDIT:');
  console.log('--------------------------------------------------');
  const varsToCheck = [
    'DATABASE_URL',
    'DATABASE_READ_URL',
    'SUPABASE_URL',
    'SUPABASE_ANON_KEY',
    'SUPABASE_SERVICE_ROLE_KEY',
    'MONGODB_URL',
    'REDIS_URL',
    'RABBITMQ_URL',
    'IMAGEKIT_PUBLIC_KEY',
    'IMAGEKIT_PRIVATE_KEY',
    'IMAGEKIT_URL_ENDPOINT',
    'GOOGLE_CLIENT_ID',
    'GOOGLE_CLIENT_SECRET',
    'JWT_SECRET',
    'NODE_ENV',
    'PORT'
  ];

  for (const v of varsToCheck) {
    const val = mergedEnv[v];
    const isSet = Boolean(val && val.trim() !== '');
    const isMock = isSet && (val.includes('mock') || val.includes('localhost') || val.includes('super-secret') || val.includes('your-'));
    console.log(`- ${v.padEnd(25)}: ${isSet ? `SET [${mask(val)}]` : 'MISSING'}${isMock ? ' (PLACEHOLDER/MOCK)' : ''}`);
  }
  console.log('\n');

  // 2. SUPABASE / POSTGRESQL CHECK
  console.log('2. MAIN DATABASE (SUPABASE / POSTGRESQL) STATUS:');
  console.log('--------------------------------------------------');
  const dbUrl = mergedEnv.DATABASE_URL || mergedEnv.SUPABASE_URL;
  if (!dbUrl) {
    console.log('❌ Status: NOT CONFIGURED (DATABASE_URL / SUPABASE_URL missing in backend/.env)');
    console.log('   Testing fallback local PostgreSQL at 127.0.0.1:5432...');
    const localPg = await checkTcp('127.0.0.1', 5432);
    console.log(`   Local PostgreSQL (127.0.0.1:5432): ${localPg.ok ? '✅ REACHABLE (Service is listening locally)' : '❌ UNREACHABLE (' + localPg.message + ')'}`);
    console.log('   👉 For Supabase: Add your Supabase PostgreSQL connection string or SUPABASE_URL to backend/.env:');
    console.log('      DATABASE_URL=postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres');
    console.log('      Or set SUPABASE_URL, which automatically aliases to DATABASE_URL');
  } else {
    if (!mergedEnv.DATABASE_URL && mergedEnv.SUPABASE_URL) {
      console.log('   ℹ️  Auto-aliased from SUPABASE_URL -> DATABASE_URL');
    }
    if (dbUrl.startsWith('postgres://') || dbUrl.startsWith('postgresql://')) {
      try {
        const parsed = new URL(dbUrl);
        const host = parsed.hostname;
        const port = Number(parsed.port) || 5432;
        console.log(`   Target host: ${host}:${port}`);
        const dbCheck = await checkTcp(host, port);
        console.log(`   Socket reachability: ${dbCheck.ok ? '✅ REACHABLE (' + dbCheck.latencyMs + 'ms)' : '❌ UNREACHABLE - ' + dbCheck.message}`);

        if (dbCheck.ok) {
          console.log('   Testing live PostgreSQL handshake with pg.Pool...');
          const pool = new Pool({ connectionString: dbUrl, connectionTimeoutMillis: 4000 });
          try {
            await pool.query('SELECT 1');
            console.log('   PostgreSQL Live Query: ✅ SUCCESS (SELECT 1 executed)');
          } catch (err: any) {
            console.log(`   PostgreSQL Live Query: ⚠️ ${err.message}`);
          } finally {
            await pool.end().catch(() => {});
          }
        }
      } catch (e: any) {
        console.log(`❌ Invalid DATABASE_URL: ${e.message}`);
      }
    } else {
      console.log(`   Configured URL type: HTTP / Supabase API (${dbUrl})`);
    }
  }

  // Supabase Client SDK Check
  const sbUrl = mergedEnv.SUPABASE_URL || (mergedEnv.DATABASE_URL?.startsWith('https://') ? mergedEnv.DATABASE_URL : undefined);
  const sbKey = mergedEnv.SUPABASE_SERVICE_ROLE_KEY || mergedEnv.SUPABASE_ANON_KEY;
  if (sbUrl && sbKey) {
    console.log(`   Testing Supabase SDK client (${sbUrl})...`);
    try {
      const client = createClient(sbUrl, sbKey);
      const { error } = await client.auth.getSession();
      if (!error) {
        console.log('   Supabase SDK Authentication: ✅ SUCCESS (Client connected)');
      } else {
        console.log(`   Supabase SDK Authentication: ⚠️ ${error.message}`);
      }
    } catch (e: any) {
      console.log(`   Supabase SDK Error: ❌ ${e.message}`);
    }
  }
  console.log('\n');

  // 3. MONGODB CHECK
  console.log('3. MONGODB STATUS:');
  console.log('--------------------------------------------------');
  const mongoUrl = mergedEnv.MONGODB_URL;
  if (!mongoUrl) {
    console.log('❌ Status: NOT CONFIGURED (MONGODB_URL missing in backend/.env)');
    console.log('   Testing fallback local MongoDB at 127.0.0.1:27017...');
    const localMongo = await checkTcp('127.0.0.1', 27017);
    console.log(`   Local MongoDB (127.0.0.1:27017): ${localMongo.ok ? '✅ REACHABLE (Service is listening locally)' : '❌ UNREACHABLE (' + localMongo.message + ')'}`);
  } else {
    try {
      const match = mongoUrl.match(/mongodb(?:\+srv)?:\/\/(?:[^@]+@)?([^/:]+)(?::(\d+))?/);
      const host = match ? match[1] : 'localhost';
      const port = match && match[2] ? Number(match[2]) : 27017;
      console.log(`   Target: ${host}:${port}`);
      const mongoCheck = await checkTcp(host, port);
      console.log(`   Socket: ${mongoCheck.ok ? '✅ REACHABLE' : '❌ UNREACHABLE (' + mongoCheck.message + ')'}`);

      if (mongoCheck.ok) {
        const mClient = new MongoClient(mongoUrl, { serverSelectionTimeoutMS: 3000 });
        try {
          await mClient.connect();
          await mClient.db().admin().ping();
          console.log('   MongoDB Live Ping: ✅ SUCCESS');
        } catch (err: any) {
          console.log(`   MongoDB Live Ping: ⚠️ ${err.message}`);
        } finally {
          await mClient.close().catch(() => {});
        }
      }
    } catch (e: any) {
      console.log(`❌ Error parsing MONGODB_URL: ${e.message}`);
    }
  }
  console.log('\n');

  // 4. REDIS CHECK
  console.log('4. REDIS STATUS:');
  console.log('--------------------------------------------------');
  const redisUrl = mergedEnv.REDIS_URL;
  if (!redisUrl) {
    console.log('❌ Status: NOT CONFIGURED (REDIS_URL missing in backend/.env)');
    console.log('   Testing fallback local Redis at 127.0.0.1:6379...');
    const localRedis = await checkTcp('127.0.0.1', 6379);
    console.log(`   Local Redis (127.0.0.1:6379): ${localRedis.ok ? '✅ REACHABLE' : '❌ UNREACHABLE (' + localRedis.message + ')'}`);
  } else {
    try {
      const parsed = new URL(redisUrl);
      const host = parsed.hostname;
      const port = Number(parsed.port) || 6379;
      console.log(`   Target: ${host}:${port}`);
      const redisCheck = await checkTcp(host, port);
      console.log(`   Socket: ${redisCheck.ok ? '✅ REACHABLE' : '❌ UNREACHABLE (' + redisCheck.message + ')'}`);

      if (redisCheck.ok) {
        const rClient = new Redis(redisUrl, { lazyConnect: true, connectTimeout: 3000 });
        try {
          await rClient.connect();
          const pong = await rClient.ping();
          console.log(`   Redis Live Ping: ✅ SUCCESS (Received ${pong})`);
        } catch (err: any) {
          console.log(`   Redis Live Ping: ⚠️ ${err.message}`);
        } finally {
          rClient.disconnect();
        }
      }
    } catch (e: any) {
      console.log(`❌ Error parsing REDIS_URL: ${e.message}`);
    }
  }
  console.log('\n');

  // 5. RABBITMQ CHECK
  console.log('5. RABBITMQ STATUS:');
  console.log('--------------------------------------------------');
  const rabbitUrl = mergedEnv.RABBITMQ_URL;
  if (!rabbitUrl) {
    console.log('❌ Status: NOT CONFIGURED (RABBITMQ_URL missing in backend/.env)');
    console.log('   Testing fallback local RabbitMQ at 127.0.0.1:5672...');
    const localRabbit = await checkTcp('127.0.0.1', 5672);
    console.log(`   Local RabbitMQ (127.0.0.1:5672): ${localRabbit.ok ? '✅ REACHABLE' : '❌ UNREACHABLE (' + localRabbit.message + ')'}`);
  } else {
    try {
      const parsed = new URL(rabbitUrl);
      const host = parsed.hostname;
      const port = Number(parsed.port) || 5672;
      console.log(`   Target: ${host}:${port}`);
      const rabbitCheck = await checkTcp(host, port);
      console.log(`   Socket: ${rabbitCheck.ok ? '✅ REACHABLE' : '❌ UNREACHABLE (' + rabbitCheck.message + ')'}`);

      if (rabbitCheck.ok) {
        try {
          const conn = await amqp.connect(rabbitUrl);
          const ch = await conn.createChannel();
          console.log('   RabbitMQ Live Channel: ✅ SUCCESS');
          await ch.close().catch(() => {});
          await conn.close().catch(() => {});
        } catch (err: any) {
          console.log(`   RabbitMQ Live Channel: ⚠️ ${err.message}`);
        }
      }
    } catch (e: any) {
      console.log(`❌ Error parsing RABBITMQ_URL: ${e.message}`);
    }
  }
  console.log('\n');

  // 6. IMAGEKIT CDN CHECK
  console.log('6. IMAGEKIT STATUS:');
  console.log('--------------------------------------------------');
  const ikPubKey = mergedEnv.IMAGEKIT_PUBLIC_KEY;
  const ikPrivKey = mergedEnv.IMAGEKIT_PRIVATE_KEY;
  const ikEndpoint = mergedEnv.IMAGEKIT_URL_ENDPOINT || 'https://ik.imagekit.io/urjavatika';

  console.log(`   Endpoint: ${ikEndpoint}`);
  console.log(`   Public Key: ${ikPubKey ? mask(ikPubKey) : 'MISSING (Using fallback mock)'}`);
  console.log(`   Private Key: ${ikPrivKey ? mask(ikPrivKey) : 'MISSING (Using fallback mock)'}`);

  const ikHttp = await checkHttp(ikEndpoint);
  console.log(`   Endpoint Accessibility: ${ikHttp.message}`);

  if (ikPrivKey && !ikPrivKey.includes('mock')) {
    const authHeader = 'Basic ' + Buffer.from(ikPrivKey + ':').toString('base64');
    const ikApi = await checkHttp('https://api.imagekit.io/v1/files?limit=1', {
      headers: { Authorization: authHeader }
    });
    console.log(`   ImageKit API Authentication: ${ikApi.ok ? '✅ SUCCESS' : '❌ FAILED - ' + ikApi.message}`);
  } else {
    console.log('   ⚠️  ImageKit is currently in MOCK MODE (fallback keys used; actual uploads will fail).');
  }
  console.log('\n');

  // 7. GOOGLE OAUTH & SERVICES CHECK
  console.log('7. GOOGLE OAUTH CONFIGURATION & REACHABILITY:');
  console.log('--------------------------------------------------');
  const googleClientId = mergedEnv.GOOGLE_CLIENT_ID;
  const googleClientSecret = mergedEnv.GOOGLE_CLIENT_SECRET;

  console.log(`   GOOGLE_CLIENT_ID: ${googleClientId ? mask(googleClientId) : 'MISSING'}`);
  console.log(`   GOOGLE_CLIENT_SECRET: ${googleClientSecret ? mask(googleClientSecret) : 'MISSING'}`);

  const googleDiscovery = await checkHttp('https://accounts.google.com/.well-known/openid-configuration');
  console.log(`   Google OAuth Discovery Endpoint: ${googleDiscovery.ok ? '✅ REACHABLE (Google servers accessible)' : '❌ UNREACHABLE (' + googleDiscovery.message + ')'}`);

  if (googleClientId) {
    if (googleClientId.endsWith('.apps.googleusercontent.com')) {
      console.log('   Google Client ID Format: ✅ VALID Google Cloud OAuth Client ID structure');
    } else {
      console.log('   Google Client ID Format: ⚠️ DOES NOT end with .apps.googleusercontent.com');
    }
  }
  console.log('\n');

  // 8. FLUTTER CLIENT <-> BACKEND TARGET ENDPOINTS CHECK
  console.log('8. FLUTTER CLIENT <-> FASTIFY BACKEND CONNECTIVITY:');
  console.log('--------------------------------------------------');
  const vercelUrl = 'https://urjaone.vercel.app';
  console.log(`   Checking Flutter Default Production Target: ${vercelUrl}/health`);
  const vercelHealth = await checkHttp(`${vercelUrl}/health`);
  console.log(`   Vercel Deployment /health: ${vercelHealth.ok ? '✅ ONLINE (' + vercelHealth.message + ')' : '❌ OFFLINE/ERROR (' + vercelHealth.message + ')'}`);

  const vercelApiHealth = await checkHttp(`${vercelUrl}/api/v1/health`);
  console.log(`   Vercel Deployment /api/v1/health: ${vercelApiHealth.ok ? '✅ ONLINE (' + vercelApiHealth.message + ')' : '❌ OFFLINE/ERROR (' + vercelApiHealth.message + ')'}`);

  console.log('\n   Checking Local Backend Instance: http://127.0.0.1:3000/health');
  const localBackend = await checkHttp('http://127.0.0.1:3000/health');
  console.log(`   Local Server (Port 3000): ${localBackend.ok ? '✅ ONLINE' : '❌ OFFLINE (' + localBackend.message + ')'}`);
  console.log('\n========================================================================\n');
}

if (require.main === module || (process.argv[1] && process.argv[1].endsWith('check-connectivity.ts'))) {
  runDiagnostics().catch(console.error);
}
