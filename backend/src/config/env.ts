import fs from 'node:fs';
import path from 'node:path';
import { Type, type Static } from '@sinclair/typebox';

export const EnvSchema = Type.Object({
  PORT: Type.Union([Type.Number(), Type.String()], { default: 3000 }),
  HOST: Type.String({ default: '0.0.0.0' }),
  NODE_ENV: Type.String({ default: 'development' }),
  LOG_LEVEL: Type.String({ default: 'info' }),
  CORS_ORIGIN: Type.String({ default: '*' }),
  JWT_SECRET: Type.String({ default: 'dev-jwt-secret-key-must-be-at-least-32-characters-long' }),
  GOOGLE_CLIENT_ID: Type.String({ default: 'mock-google-client-id.apps.googleusercontent.com' }),
  GOOGLE_CLIENT_SECRET: Type.Optional(Type.String()),
  IMAGEKIT_PUBLIC_KEY: Type.String({ default: 'public_mock_imagekit_key' }),
  IMAGEKIT_PRIVATE_KEY: Type.String({ default: 'private_mock_imagekit_key_strictly_secret' }),
  IMAGEKIT_URL_ENDPOINT: Type.String({ default: 'https://ik.imagekit.io/urjavatika' }),
  DATABASE_URL: Type.Optional(Type.String()),
  DATABASE_READ_URL: Type.Optional(Type.String()),
  SUPABASE_URL: Type.Optional(Type.String()),
  SUPABASE_ANON_KEY: Type.Optional(Type.String()),
  SUPABASE_SERVICE_ROLE_KEY: Type.Optional(Type.String()),
  MONGODB_URL: Type.Optional(Type.String()),
  REDIS_URL: Type.Optional(Type.String()),
  RABBITMQ_URL: Type.Optional(Type.String()),
});

export type EnvConfig = Static<typeof EnvSchema>;

function loadExternalEnv(): void {
  const candidates = [
    'C:\\Users\\vivek\\Desktop\\env\\.env',
    path.resolve(process.cwd(), '../env/.env'),
  ];
  for (const candidate of candidates) {
    try {
      if (fs.existsSync(candidate)) {
        const raw = fs.readFileSync(candidate, 'utf-8');
        for (const line of raw.split('\n')) {
          const trimmed = line.trim();
          if (!trimmed || trimmed.startsWith('#')) continue;
          const eq = trimmed.indexOf('=');
          if (eq !== -1) {
            const key = trimmed.slice(0, eq).trim();
            const val = trimmed.slice(eq + 1).trim().replace(/^["']|["']$/g, '');
            if (!process.env[key] && val) {
              process.env[key] = val;
            }
          }
        }
      }
    } catch {
      // In sandbox or production, external file might not exist or be accessible
    }
  }
}
loadExternalEnv();

function cleanEnv(raw: Record<string, string | undefined>): Record<string, unknown> {
  const cleaned: Record<string, unknown> = {};
  for (const [key, val] of Object.entries(raw)) {
    if (val === undefined || val === '') continue;
    let trimmed = val.trim();
    if (
      (trimmed.startsWith('"') && trimmed.endsWith('"')) ||
      (trimmed.startsWith("'") && trimmed.endsWith("'"))
    ) {
      trimmed = trimmed.slice(1, -1).trim();
    }
    cleaned[key] = trimmed;
  }

  // Auto-alias SUPABASE_URL to DATABASE_URL if DATABASE_URL is not explicitly configured
  if (!cleaned.DATABASE_URL && cleaned.SUPABASE_URL) {
    cleaned.DATABASE_URL = cleaned.SUPABASE_URL;
  }
  // And vice-versa
  if (!cleaned.SUPABASE_URL && cleaned.DATABASE_URL) {
    cleaned.SUPABASE_URL = cleaned.DATABASE_URL;
  }

  if (!cleaned.PORT || cleaned.PORT === '') {
    cleaned.PORT = 3000;
  } else if (!isNaN(Number(cleaned.PORT))) {
    cleaned.PORT = Number(cleaned.PORT);
  }
  return cleaned;
}

export const envOptions = {
  confKey: 'config',
  schema: EnvSchema,
  dotenv: process.env.NODE_ENV === 'production' ? false : true,
  data: cleanEnv(process.env),
};

declare module 'fastify' {
  interface FastifyInstance {
    config: EnvConfig;
  }
}
