import { Type, type Static } from '@sinclair/typebox';

export const ImageKitAuthResponseSchema = Type.Object({
  token: Type.String({ description: 'Unique random UUID one-time nonce' }),
  expire: Type.Number({ description: 'Unix epoch expiration timestamp' }),
  signature: Type.String({ description: 'Server-calculated HMAC-SHA1 signature' }),
  publicKey: Type.String({ description: 'Safe public ImageKit API key' }),
});

export type ImageKitAuthResponse = Static<typeof ImageKitAuthResponseSchema>;

export const ImageKitAuthRouteSchema = {
  description:
    'Generates a temporary HMAC-SHA1 signature allowing the frontend client to upload directly to ImageKit CDN without revealing the private key. Requires Bearer JWT.',
  tags: ['Media'],
  security: [{ bearerAuth: [] }],
  response: {
    200: ImageKitAuthResponseSchema,
  },
};
