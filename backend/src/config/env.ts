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
  GOOGLE_CLIENT_ID: Type.String({ default: 'mock-google-client-id.apps.googleusercontent.com' }),
  IMAGEKIT_PUBLIC_KEY: Type.String({ default: 'public_mock_imagekit_key' }),
  IMAGEKIT_PRIVATE_KEY: Type.String({ default: 'private_mock_imagekit_key_strictly_secret' }),
  IMAGEKIT_URL_ENDPOINT: Type.String({ default: 'https://ik.imagekit.io/urjavatika' }),
  DATABASE_URL: Type.Optional(Type.String()),
  DATABASE_READ_URL: Type.Optional(Type.String()),
  MONGODB_URL: Type.Optional(Type.String()),
  REDIS_URL: Type.Optional(Type.String()),
  RABBITMQ_URL: Type.Optional(Type.String()),
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
