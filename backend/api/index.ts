import type { FastifyInstance } from 'fastify';
import { buildApp } from '../src/app';

let appPromise: Promise<FastifyInstance> | null = null;

function getFastifyApp(): Promise<FastifyInstance> {
  if (!appPromise) {
    appPromise = (async () => {
      const app = buildApp({
        logger: false,
      });
      await app.ready();
      return app;
    })();
  }
  return appPromise;
}

export default async function handler(req: any, res: any): Promise<void> {
  const app = await getFastifyApp();

  // On Vercel, rewrites can map routes to /api. Restore the original user-facing URL:
  const matchedPath = req.headers['x-matched-path'] || req.headers['x-forwarded-uri'];
  if (matchedPath && (req.url === '/api' || req.url === '/api/')) {
    req.url = matchedPath;
  }

  return new Promise<void>((resolve, reject) => {
    res.on('finish', resolve);
    res.on('close', resolve);
    res.on('error', reject);
    app.server.emit('request', req, res);
  });
}
