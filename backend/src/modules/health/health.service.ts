import type { HealthResponse } from './health.schema';

export class HealthService {
  public static getHealth(environment: string): HealthResponse {
    const mem = process.memoryUsage();
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: Number(process.uptime().toFixed(2)),
      service: 'urjavatika-backend',
      environment,
      memory: {
        heapUsedMB: Number((mem.heapUsed / 1024 / 1024).toFixed(2)),
        rssMB: Number((mem.rss / 1024 / 1024).toFixed(2)),
      },
    };
  }
}
