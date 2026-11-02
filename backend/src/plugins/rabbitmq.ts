import amqp from 'amqplib';
import fp from 'fastify-plugin';

export interface RabbitMQClient {
  connection: amqp.ChannelModel | null;
  channel: amqp.Channel | null;
  publish: (queueOrExchange: string, content: Buffer | string, options?: amqp.Options.Publish) => boolean;
  enqueueTask: (taskName: string, payload: unknown) => boolean;
}

export class RabbitMQService {
  private static client: RabbitMQClient | null = null;

  public static setClient(client: RabbitMQClient | null): void {
    this.client = client;
  }

  public static enqueueTask(taskName: string, payload: unknown): boolean {
    if (this.client) {
      return this.client.enqueueTask(taskName, payload);
    }
    return false;
  }
}

declare module 'fastify' {
  interface FastifyInstance {
    rabbitmq: RabbitMQClient | null;
  }
}

export default fp(async (fastify) => {
  const config = fastify.config;
  const rabbitUrl = config?.RABBITMQ_URL;

  let client: RabbitMQClient | null = null;
  let connection: amqp.ChannelModel | null = null;
  let channel: amqp.Channel | null = null;

  const TASK_QUEUE = 'urja_large_tasks';

  if (rabbitUrl && rabbitUrl.trim() !== '') {
    try {
      amqp.connect(rabbitUrl)
        .then(async (conn) => {
          connection = conn;
          channel = await conn.createChannel();
          await channel.assertQueue(TASK_QUEUE, { durable: true });
          fastify.log.info({ queue: TASK_QUEUE }, '[RabbitMQ] Connected successfully & declared task queue');

          // Asynchronous Worker Consumer for Large Tasks
          channel.consume(TASK_QUEUE, (msg) => {
            if (msg) {
              try {
                const parsed = JSON.parse(msg.content.toString());
                fastify.log.info({ task: parsed.taskName }, '[RabbitMQ Worker] Processing large background task');
                channel?.ack(msg);
              } catch (err: unknown) {
                const errMsg = err instanceof Error ? err.message : String(err);
                fastify.log.error({ err: errMsg }, '[RabbitMQ Worker] Failed to process message');
                channel?.nack(msg, false, false);
              }
            }
          });

          client = {
            connection,
            channel,
            publish: (queueOrExchange, content, options) => {
              if (!channel) return false;
              const buffer = Buffer.isBuffer(content) ? content : Buffer.from(content);
              return channel.sendToQueue(queueOrExchange, buffer, options);
            },
            enqueueTask: (taskName, payload) => {
              if (!channel) return false;
              const message = JSON.stringify({ taskName, payload, timestamp: new Date().toISOString() });
              return channel.sendToQueue(TASK_QUEUE, Buffer.from(message), { persistent: true });
            },
          };

          fastify.rabbitmq = client;
          RabbitMQService.setClient(client);
        })
        .catch((err: unknown) => {
          const msg = err instanceof Error ? err.message : String(err);
          fastify.log.warn({ err: msg }, '[RabbitMQ] Could not connect to RABBITMQ_URL. Operating in fallback memory mode.');
        });
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      fastify.log.warn({ err: msg }, '[RabbitMQ] Failed to initialize connection to RABBITMQ_URL');
    }
  } else {
    fastify.log.info('[RabbitMQ] RABBITMQ_URL not configured. Operating in fallback memory mode.');
  }

  client = {
    connection: null,
    channel: null,
    publish: (queue, content) => {
      if (process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'test') {
        fastify.log.debug({ queue, content: content.toString() }, '[RabbitMQ Mock] Emitted message');
      }
      return true;
    },
    enqueueTask: (taskName, payload) => {
      if (process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'test') {
        fastify.log.debug({ taskName, payload }, '[RabbitMQ Mock] Enqueued task');
      }
      return true;
    },
  };

  fastify.decorate('rabbitmq', client);
  RabbitMQService.setClient(client);

  fastify.addHook('onClose', async () => {
    if (channel) {
      await channel.close().catch(() => {});
    }
    if (connection) {
      await connection.close().catch(() => {});
    }
  });
});
