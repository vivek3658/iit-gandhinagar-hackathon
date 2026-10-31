import crypto from 'node:crypto';
import type { ImageKitAuthResponse } from './media.schema';

export class MediaService {
  /**
   * Generates HMAC-SHA1 signature for secure direct client-side upload to ImageKit.
   * The private key NEVER leaves the server.
   */
  public static getImageKitAuth(
    privateKey: string,
    publicKey: string,
    expireSeconds = 1800, // 30 minutes validity
  ): ImageKitAuthResponse {
    const token = crypto.randomUUID();
    const expire = Math.floor(Date.now() / 1000) + expireSeconds;

    const signature = crypto
      .createHmac('sha1', privateKey)
      .update(token + expire)
      .digest('hex');

    return {
      token,
      expire,
      signature,
      publicKey,
    };
  }
}
