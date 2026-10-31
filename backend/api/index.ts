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
  app.server.emit('request', req, res);
}
