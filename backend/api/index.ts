import type { FastifyInstance } from 'fastify';
import { buildApp } from '../src/app';

let appInstance: FastifyInstance | null = null;

async function getFastifyApp(): Promise<FastifyInstance> {
  if (!appInstance) {
    appInstance = buildApp({
      logger: process.env.NODE_ENV === 'production' ? false : true,
    });
    await appInstance.ready();
  }
  return appInstance;
}

export default async function handler(req: any, res: any): Promise<void> {
  const app = await getFastifyApp();

  // On Vercel, rewrites can map routes to /api. Restore the original user-facing URL:
  const originalUrl = req.headers['x-matched-path'] || req.headers['x-forwarded-uri'];
  if (originalUrl && (req.url === '/api' || req.url === '/api/')) {
    req.url = originalUrl;
  }

  app.server.emit('request', req, res);
}
