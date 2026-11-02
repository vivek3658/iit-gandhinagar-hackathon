import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { FastifyInstance } from 'fastify';
import { buildApp } from '../src/app';
import { parsePostgresUrl } from '../src/plugins/db';

describe('Health Module & Core Gateway', () => {
  let app: FastifyInstance;

  beforeAll(async () => {
    app = buildApp({ logger: false });
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /health returns 200 and valid health payload', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/health',
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.status).toBe('ok');
    expect(body.service).toBe('urjavatika-backend');
    expect(typeof body.uptime).toBe('number');
    expect(typeof body.memory.heapUsedMB).toBe('number');
  });

  it('GET /api/v1/health returns 200 with prefixed route', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/v1/health',
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.status).toBe('ok');
    expect(body.service).toBe('urjavatika-backend');
  });

  it('GET /api/v1/unknown-endpoint returns consistent 404 shape', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/v1/unknown-endpoint',
    });

    expect(res.statusCode).toBe(404);
    const body = JSON.parse(res.body);
    expect(body).toEqual({
      statusCode: 404,
      error: 'NotFound',
      message: 'Route GET /api/v1/unknown-endpoint not found',
    });
  });

  it('GET /docs/json returns valid OpenAPI 3.1 specification', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/docs/json',
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.openapi).toBe('3.1.0');
    expect(body.info.title).toContain('UrjaVatika');
    expect(body.paths['/health']).toBeDefined();
  });

  it('parsePostgresUrl parses URLs with special characters and removes literal brackets', () => {
    const url1 = 'postgresql://postgres:[my_pass#123]@db.urppcoxoeswbfpbeabpz.supabase.co:5432/postgres';
    const parsed1 = parsePostgresUrl(url1);
    expect(parsed1).not.toBeNull();
    expect(parsed1?.user).toBe('postgres');
    expect(parsed1?.password).toBe('my_pass#123');
    expect(parsed1?.host).toBe('db.urppcoxoeswbfpbeabpz.supabase.co');
    expect(parsed1?.port).toBe(5432);
    expect(parsed1?.database).toBe('postgres');
    expect(parsed1?.ssl).toEqual({ rejectUnauthorized: false });

    const url2 = 'postgresql://postgres.myproject:pass?word@aws-0-ap-south-1.pooler.supabase.com:6543/postgres?pgbouncer=true';
    const parsed2 = parsePostgresUrl(url2);
    expect(parsed2).not.toBeNull();
    expect(parsed2?.user).toBe('postgres.myproject');
    expect(parsed2?.password).toBe('pass?word');
    expect(parsed2?.port).toBe(6543);
  });
});
