import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { FastifyInstance } from 'fastify';
import { buildApp } from '../src/app';

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
});
