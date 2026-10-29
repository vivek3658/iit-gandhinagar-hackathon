import type { FastifyReply, FastifyRequest } from 'fastify';
import { AuthService } from './auth.service';
import type {
  CompleteProfileBody,
  CompleteProfileResponse,
  GenericActionResponse,
  GoogleAuthBody,
  GoogleAuthResponse,
  MeResponse,
  RefreshTokenBody,
  RefreshTokenResponse,
} from './auth.schema';

export class AuthController {
  public static async googleAuth(
    request: FastifyRequest,
    reply: FastifyReply,
  ): Promise<GoogleAuthResponse> {
    try {
      const googleClientId =
        request.server.config?.GOOGLE_CLIENT_ID ||
        process.env.GOOGLE_CLIENT_ID ||
        'mock-google-client-id.apps.googleusercontent.com';

      const jwtSignFn = (payload: { id: string; email: string; role: 'CITIZEN' | 'ADMIN' }): string => {
        return request.server.jwt.sign(payload);
      };

      const body = request.body as GoogleAuthBody;
      return await AuthService.authenticateWithGoogle(body.idToken, jwtSignFn, googleClientId);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Google authentication failed';
      return reply.badRequest(msg);
    }
  }

  public static async completeProfile(
    request: FastifyRequest,
    reply: FastifyReply,
  ): Promise<CompleteProfileResponse> {
    const userId = request.user?.id;
    if (!userId) {
      return reply.unauthorized('User identity not verified');
    }

    try {
      const body = request.body as CompleteProfileBody;
      const user = AuthService.completeProfile(userId, body);
      return {
        success: true,
        isProfileComplete: user.isProfileComplete,
        user,
      };
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Failed to update profile';
      return reply.badRequest(msg);
    }
  }

  public static async getMe(
    request: FastifyRequest,
    reply: FastifyReply,
  ): Promise<MeResponse> {
    const userId = request.user?.id;
    if (!userId) {
      return reply.unauthorized('User identity not verified');
    }

    try {
      const user = AuthService.getMe(userId);
      return { user };
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'User not found';
      return reply.notFound(msg);
    }
  }

  public static async refreshToken(
    request: FastifyRequest,
    reply: FastifyReply,
  ): Promise<RefreshTokenResponse> {
    try {
      const jwtSignFn = (payload: { id: string; email: string; role: 'CITIZEN' | 'ADMIN' }): string => {
        return request.server.jwt.sign(payload);
      };

      const body = request.body as RefreshTokenBody;
      return AuthService.refreshTokens(body.refreshToken, jwtSignFn);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Invalid or expired refresh token';
      return reply.unauthorized(msg);
    }
  }

  public static async logout(
    request: FastifyRequest,
    _reply: FastifyReply,
  ): Promise<GenericActionResponse> {
    const body = request.body as RefreshTokenBody | undefined;
    const refreshToken = body?.refreshToken;
    const userId = request.user?.id;

    AuthService.logout(refreshToken, userId);

    return {
      success: true,
      message: 'Logged out successfully. Tokens revoked.',
    };
  }

  public static async deleteAccount(
    request: FastifyRequest,
    reply: FastifyReply,
  ): Promise<GenericActionResponse> {
    const userId = request.user?.id;
    if (!userId) {
      return reply.unauthorized('User identity not verified');
    }

    AuthService.deleteAccount(userId);

    return {
      success: true,
      message: 'Account has been deleted and personal information anonymized.',
    };
  }
}
