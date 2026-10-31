import { buildApp } from './app';

async function start(): Promise<void> {
  const app = buildApp();

  try {
    await app.ready();

    const port = Number(app.config?.PORT || process.env.PORT || 3000);
    const host = app.config?.HOST || process.env.HOST || '0.0.0.0';

    await app.listen({ port, host });
    app.log.info(`UrjaVatika backend listening on http://${host}:${port}`);
    app.log.info(`Health check available at http://${host}:${port}/health`);
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }

  // Graceful shutdown
  const signals: NodeJS.Signals[] = ['SIGINT', 'SIGTERM'];
  for (const signal of signals) {
    process.on(signal, async () => {
      app.log.info(`Received ${signal}, closing server gracefully...`);
      try {
        await app.close();
        app.log.info('Server closed cleanly');
        process.exit(0);
      } catch (closeErr) {
        app.log.error(closeErr);
        process.exit(1);
      }
    });
  }
}

void start();
