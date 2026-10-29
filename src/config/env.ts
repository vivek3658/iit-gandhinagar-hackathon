import { Type, type Static } from '@sinclair/typebox';

export const EnvSchema = Type.Object({
  PORT: Type.Number({ default: 3000 }),
  HOST: Type.String({ default: '0.0.0.0' }),
  NODE_ENV: Type.Union([
    Type.Literal('development'),
    Type.Literal('production'),
    Type.Literal('test'),
  ], { default: 'development' }),
  LOG_LEVEL: Type.Union([
    Type.Literal('fatal'),
    Type.Literal('error'),
    Type.Literal('warn'),
    Type.Literal('info'),
    Type.Literal('debug'),
    Type.Literal('trace'),
  ], { default: 'info' }),
  CORS_ORIGIN: Type.String({ default: '*' }),
  JWT_SECRET: Type.String({ default: 'dev-jwt-secret-key-must-be-at-least-32-characters-long' }),
});

export type EnvConfig = Static<typeof EnvSchema>;

export const envOptions = {
  confKey: 'config',
  schema: EnvSchema,
  dotenv: true,
  data: process.env,
};

declare module 'fastify' {
  interface FastifyInstance {
    config: EnvConfig;
  }
}
