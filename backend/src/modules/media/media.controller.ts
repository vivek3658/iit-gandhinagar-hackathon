import type { FastifyReply, FastifyRequest } from 'fastify';
import { MediaService } from './media.service';
import type { ImageKitAuthResponse } from './media.schema';

export class MediaController {
  public static async getImageKitAuth(
    request: FastifyRequest,
    _reply: FastifyReply,
  ): Promise<ImageKitAuthResponse> {
    const rawPrivateKey =
      request.server.config?.IMAGEKIT_PRIVATE_KEY ||
      process.env.IMAGEKIT_PRIVATE_KEY ||
      'private_mock_imagekit_key_strictly_secret';

    const rawPublicKey =
      request.server.config?.IMAGEKIT_PUBLIC_KEY ||
      process.env.IMAGEKIT_PUBLIC_KEY ||
      'public_mock_imagekit_key';

    const privateKey = rawPrivateKey.trim().replace(/^["']|["']$/g, '');
    const publicKey = rawPublicKey.trim().replace(/^["']|["']$/g, '');

    return MediaService.getImageKitAuth(privateKey, publicKey);
  }
}
