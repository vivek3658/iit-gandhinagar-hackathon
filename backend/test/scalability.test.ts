import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { performance } from 'node:perf_hooks';
import { buildApp } from '../src/app';

interface BenchmarkResult {
  instances: number;
  workload: 'READ' | 'WRITE' | 'HYBRID_EDGE';
  totalRequests: number;
  durationMs: number;
  reqPerSec: number;
  p50: number;
  p95: number;
  p99: number;
}

describe('UrjaVatika in-process request behavior (not an HTTP load test)', () => {
  // Pool of up to 6 in-process Fastify apps; inject() bypasses the network stack.
  let cluster6: FastifyInstance[] = [];
  let authToken: string;

  beforeAll(async () => {
    // Build and initialize 6 Fastify instances
    cluster6 = await Promise.all(
      Array.from({ length: 6 }, async () => {
        const app = buildApp({ logger: false });
        await app.ready();
        return app;
      }),
    );

    // Initialize mock user & obtain JWT token on instance 0
    const login = await cluster6[0].inject({
      method: 'POST',
      url: '/api/v1/auth/google',
      payload: { idToken: 'mock_test_token_bench_scalability' },
    });
    expect(login.statusCode).toBe(200);
    const parsed = JSON.parse(login.body);
    authToken = parsed.accessToken;
  });

  afterAll(async () => {
    await Promise.all(cluster6.map((app) => app.close()));
  });

  // Helper: Execute a concurrent batch across an N-instance cluster
  async function runClusterBenchmark(
    clusterSize: number,
    totalRequests: number,
    concurrency: number,
    requestFn: (app: FastifyInstance, idx: number) => Promise<{ statusCode: number }>,
    workload: 'READ' | 'WRITE' | 'HYBRID_EDGE',
  ): Promise<BenchmarkResult> {
    const activeInstances = cluster6.slice(0, clusterSize);
    const latencies: number[] = [];
    let rrCounter = 0;

    const startTime = performance.now();

    for (let i = 0; i < totalRequests; i += concurrency) {
      const batchSize = Math.min(concurrency, totalRequests - i);
      const batch = Array.from({ length: batchSize }).map(async (_, offset) => {
        const reqIdx = i + offset;
        const targetApp = activeInstances[rrCounter++ % clusterSize];
        const reqStart = performance.now();
        const res = await requestFn(targetApp, reqIdx);
        const elapsed = performance.now() - reqStart;
        latencies.push(elapsed);
        return res;
      });

      const results = await Promise.all(batch);
      for (const res of results) {
        expect(res.statusCode).toBe(200);
      }
    }

    const durationMs = performance.now() - startTime;
    const reqPerSec = Math.round((totalRequests / durationMs) * 1000);

    latencies.sort((a, b) => a - b);
    const p50 = latencies[Math.floor(latencies.length * 0.5)] || 0;
    const p95 = latencies[Math.floor(latencies.length * 0.95)] || 0;
    const p99 = latencies[Math.floor(latencies.length * 0.99)] || 0;

    return {
      instances: clusterSize,
      workload,
      totalRequests,
      durationMs,
      reqPerSec,
      p50,
      p95,
      p99,
    };
  }

  // --------------------------------------------------------------------------
  // TEST 1: In-process health route behavior (1 -> 2 -> 4 -> 6 app objects)
  // --------------------------------------------------------------------------
  it('1. Measures injected health responses across 1, 2, 4, and 6 app objects', async () => {
    const totalRequests = 600;
    const concurrency = 30;
    const tiers = [1, 2, 4, 6];
    const results: BenchmarkResult[] = [];

    for (const size of tiers) {
      const result = await runClusterBenchmark(
        size,
        totalRequests,
        concurrency,
        async (app) => {
          return app.inject({
            method: 'GET',
            url: '/health',
          });
        },
        'READ',
      );
      results.push(result);
    }

    console.log('\n================ READ WORKLOAD SCALING LEDGER ================');
    console.log('In-process apps | inject req/s (not HTTP) | p50 (ms) | p95 (ms) | p99 (ms) | Relative rate');
    console.log('-----------------------------------------------------------------------');
    const baseline = results[0].reqPerSec;
    for (const r of results) {
      const speedup = (r.reqPerSec / baseline).toFixed(2);
      console.log(
        `   ${r.instances}      |    ${r.reqPerSec.toString().padStart(6)} req/s    |  ${r.p50.toFixed(2).padStart(5)}   |  ${r.p95.toFixed(2).padStart(5)}   |  ${r.p99.toFixed(2).padStart(5)}   |  ${speedup}x`,
      );
    }
    console.log('=======================================================================\n');

    // Assertions: 4 & 6 instances must maintain low p95 latency and sustain high throughput
    const res4 = results.find((r) => r.instances === 4)!;
    const res6 = results.find((r) => r.instances === 6)!;

    expect(res4.p95).toBeLessThan(120);
    expect(res6.p95).toBeLessThan(120);
    expect(res4.reqPerSec).toBeGreaterThan(1000); // Sustains high-throughput capacity in test harness
    expect(res6.reqPerSec).toBeGreaterThan(1000);
  });

  // --------------------------------------------------------------------------
  // TEST 2: In-process mutation behavior (1 -> 2 -> 4 -> 6 app objects)
  // --------------------------------------------------------------------------
  it('2. Measures injected mutation responses across 1, 2, 4, and 6 app objects', async () => {
    const totalRequests = 300;
    const concurrency = 20;
    const tiers = [1, 2, 4, 6];
    const results: BenchmarkResult[] = [];

    for (const size of tiers) {
      const result = await runClusterBenchmark(
        size,
        totalRequests,
        concurrency,
        async (app, _idx) => {
          return app.inject({
            method: 'POST',
            url: '/api/v1/mascot/interact',
            headers: { authorization: `Bearer ${authToken}` },
            payload: { action: 'PET' },
          });
        },
        'WRITE',
      );
      results.push(result);
    }

    console.log('\n================ WRITE WORKLOAD SCALING LEDGER ================');
    console.log('In-process apps | inject ops/s (not HTTP) | p50 (ms) | p95 (ms) | p99 (ms) | Shared-store contention');
    console.log('-----------------------------------------------------------------------');
    for (const r of results) {
      console.log(
        `   ${r.instances}      |    ${r.reqPerSec.toString().padStart(6)} ops/s    |  ${r.p50.toFixed(2).padStart(5)}   |  ${r.p95.toFixed(2).padStart(5)}   |  ${r.p99.toFixed(2).padStart(5)}   |   not measured`,
      );
    }
    console.log('=======================================================================\n');

    const res4 = results.find((r) => r.instances === 4)!;
    const res6 = results.find((r) => r.instances === 6)!;
    expect(res4.p95).toBeLessThan(150);
    expect(res6.p95).toBeLessThan(150);
  });

});
