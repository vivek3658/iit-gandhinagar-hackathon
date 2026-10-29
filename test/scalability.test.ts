import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { performance } from 'node:perf_hooks';
import { buildApp } from '../src/app';

describe('Auth & Core Gateway Scalability Benchmarking', () => {
  let app: FastifyInstance;

  beforeAll(async () => {
    app = buildApp({ logger: false });
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
  });

  it('measures high-concurrency throughput and p95 latency under burst load', async () => {
    const totalRequests = 1000;
    const concurrency = 50;
    const latencies: number[] = [];

    const startTime = performance.now();

    // Execute in batches of 50 concurrent requests
    for (let i = 0; i < totalRequests; i += concurrency) {
      const batch = Array.from({ length: concurrency }).map(async (_, idx) => {
        const citizenIndex = i + idx;
        const reqStart = performance.now();
        const res = await app.inject({
          method: 'POST',
          url: '/api/v1/auth/google',
          payload: { idToken: `mock_test_token_bench_${citizenIndex}` },
        });
        const reqDuration = performance.now() - reqStart;
        latencies.push(reqDuration);
        return res;
      });

      const results = await Promise.all(batch);
      for (const res of results) {
        expect(res.statusCode).toBe(200);
      }
    }

    const totalTimeMs = performance.now() - startTime;
    const reqPerSec = Math.round((totalRequests / totalTimeMs) * 1000);

    // Calculate percentiles
    latencies.sort((a, b) => a - b);
    const p50 = latencies[Math.floor(latencies.length * 0.5)] || 0;
    const p95 = latencies[Math.floor(latencies.length * 0.95)] || 0;
    const p99 = latencies[Math.floor(latencies.length * 0.99)] || 0;

    // Log benchmark ledger
    console.log(`\n================ SCALABILITY BENCHMARK REPORT ================`);
    console.log(`Total Requests:         ${totalRequests} requests`);
    console.log(`Concurrency Batch:      ${concurrency} parallel connections`);
    console.log(`Total Elapsed Time:     ${totalTimeMs.toFixed(2)} ms`);
    console.log(`Throughput:             ${reqPerSec.toLocaleString()} requests/second`);
    console.log(`p50 Latency:            ${p50.toFixed(2)} ms`);
    console.log(`p95 Latency:            ${p95.toFixed(2)} ms`);
    console.log(`p99 Latency:            ${p99.toFixed(2)} ms`);
    console.log(`==============================================================\n`);

    // Latency SLO budget assertions
    expect(p95).toBeLessThan(50); // Under 50ms p95 for end-to-end auth pipeline
    expect(reqPerSec).toBeGreaterThan(500); // Exceeds 500 req/s in single-process test harness
  });
});
