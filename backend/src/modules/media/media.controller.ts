import type { FastifyReply, FastifyRequest } from 'fastify';
import { MediaService } from './media.service';
import type { ImageKitAuthResponse } from './media.schema';

export class MediaController {
  public static async getImageKitAuth(
    request: FastifyRequest,
    _reply: FastifyReply,
  ): Promise<ImageKitAuthResponse> {
    const privateKey =
      request.server.config?.IMAGEKIT_PRIVATE_KEY ||
      process.env.IMAGEKIT_PRIVATE_KEY ||
      'private_mock_imagekit_key_strictly_secret';

    const publicKey =
      request.server.config?.IMAGEKIT_PUBLIC_KEY ||
      process.env.IMAGEKIT_PUBLIC_KEY ||
      'public_mock_imagekit_key';

    return MediaService.getImageKitAuth(privateKey, publicKey);
  }
}
