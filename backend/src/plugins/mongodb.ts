import { MongoClient } from 'mongodb';
import fp from 'fastify-plugin';
import { ActivityService } from '../modules/activity/activity.service';

declare module 'fastify' {
  interface FastifyInstance {
    mongo: MongoClient | null;
  }
}

export default fp(async (fastify) => {
  const config = fastify.config;
  const mongoUrl = config?.MONGODB_URL;

  let mongoClient: MongoClient | null = null;

  if (mongoUrl && mongoUrl.trim() !== '') {
    try {
      mongoClient = new MongoClient(mongoUrl, {
        serverSelectionTimeoutMS: 4000,
        connectTimeoutMS: 4000,
      });

      // Connect asynchronously
      mongoClient.connect()
        .then(() => {
          fastify.log.info('[MongoDB] Connected successfully to MongoDB');
          ActivityService.setMongoClient(mongoClient);
        })
        .catch((err: unknown) => {
          const msg = err instanceof Error ? err.message : String(err);
          fastify.log.warn({ err: msg }, '[MongoDB] Could not connect to MONGODB_URL. Operating in fallback memory mode.');
        });
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      fastify.log.warn({ err: msg }, '[MongoDB] Failed to initialize MongoClient');
    }
  } else {
    fastify.log.info('[MongoDB] MONGODB_URL not configured. Operating in fallback memory mode.');
  }

  fastify.decorate('mongo', mongoClient);
  ActivityService.setMongoClient(mongoClient);

  fastify.addHook('onClose', async () => {
    if (mongoClient) {
      await mongoClient.close().catch((err: unknown) => fastify.log.error(err, '[MongoDB] Error closing connection'));
    }
  });
});
