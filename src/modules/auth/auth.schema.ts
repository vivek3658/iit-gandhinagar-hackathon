import { Type, type Static } from '@sinclair/typebox';

// --- Shared Core Types ---
export const UserRoleSchema = Type.Union([Type.Literal('CITIZEN'), Type.Literal('ADMIN')]);

export const UserSchema = Type.Object({
  id: Type.String({ format: 'uuid' }),
  email: Type.String({ format: 'email' }),
  name: Type.String(),
  avatarUrl: Type.Union([Type.String(), Type.Null()]),
  dob: Type.Union([Type.String(), Type.Null()]),
  district: Type.Union([Type.String(), Type.Null()]),
  role: UserRoleSchema,
  isProfileComplete: Type.Boolean(),
  points: Type.Number(),
  createdAt: Type.String(),
  updatedAt: Type.String(),
});

export type UserDto = Static<typeof UserSchema>;

// --- 1. Google One-Button Auth ---
export const GoogleAuthBodySchema = Type.Object({
  idToken: Type.String({ minLength: 10, description: 'Google OAuth idToken obtained by frontend client' }),
});

export type GoogleAuthBody = Static<typeof GoogleAuthBodySchema>;

export const GoogleAuthResponseSchema = Type.Object({
  isNewUser: Type.Boolean({ description: 'True if citizen account was just created' }),
  isProfileComplete: Type.Boolean({ description: 'False if onboarding (DOB, district) is pending' }),
  accessToken: Type.String({ description: '15-minute stateless JWT access token' }),
  refreshToken: Type.String({ description: '30-day rotated refresh token' }),
  user: UserSchema,
});

export type GoogleAuthResponse = Static<typeof GoogleAuthResponseSchema>;

// --- 2. Complete Profile ---
export const CompleteProfileBodySchema = Type.Object({
  dob: Type.Optional(Type.String({ description: 'Date of birth (YYYY-MM-DD)' })),
  district: Type.String({ minLength: 2, maxLength: 64, description: 'Gujarat district for state leaderboard' }),
  avatarUrl: Type.Optional(Type.String({ description: 'Optimized ImageKit CDN avatar URL' })),
});

export type CompleteProfileBody = Static<typeof CompleteProfileBodySchema>;

export const CompleteProfileResponseSchema = Type.Object({
  success: Type.Boolean(),
  isProfileComplete: Type.Boolean(),
  user: UserSchema,
});

export type CompleteProfileResponse = Static<typeof CompleteProfileResponseSchema>;

// --- 3. Refresh Token ---
export const RefreshTokenBodySchema = Type.Object({
  refreshToken: Type.String({ minLength: 10, description: 'Active refresh token' }),
});

export type RefreshTokenBody = Static<typeof RefreshTokenBodySchema>;

export const RefreshTokenResponseSchema = Type.Object({
  accessToken: Type.String(),
  refreshToken: Type.String(),
});

export type RefreshTokenResponse = Static<typeof RefreshTokenResponseSchema>;

// --- 4. Get Current User ---
export const MeResponseSchema = Type.Object({
  user: UserSchema,
});

export type MeResponse = Static<typeof MeResponseSchema>;

// --- 5. Logout & Delete Account ---
export const GenericActionResponseSchema = Type.Object({
  success: Type.Boolean(),
  message: Type.String(),
});

export type GenericActionResponse = Static<typeof GenericActionResponseSchema>;

// --- Fastify Route Definitions ---
export const GoogleAuthRouteSchema = {
  description: 'One-button Google Sign-In and Registration. Automatically routes new vs returning users.',
  tags: ['Auth'],
  body: GoogleAuthBodySchema,
  response: {
    200: GoogleAuthResponseSchema,
  },
};

export const CompleteProfileRouteSchema = {
  description: 'Completes profile onboarding (DOB, Gujarat district, avatar). Requires Bearer JWT.',
  tags: ['Auth'],
  security: [{ bearerAuth: [] }],
  body: CompleteProfileBodySchema,
  response: {
    200: CompleteProfileResponseSchema,
  },
};

export const MeRouteSchema = {
  description: 'Retrieves current authenticated citizen profile and Urja points. Requires Bearer JWT.',
  tags: ['Auth'],
  security: [{ bearerAuth: [] }],
  response: {
    200: MeResponseSchema,
  },
};

export const RefreshTokenRouteSchema = {
  description: 'Rotates refresh token and issues a fresh 15-minute access JWT.',
  tags: ['Auth'],
  body: RefreshTokenBodySchema,
  response: {
    200: RefreshTokenResponseSchema,
  },
};

export const LogoutRouteSchema = {
  description: 'Revokes active refresh token and invalidates session. Requires Bearer JWT.',
  tags: ['Auth'],
  security: [{ bearerAuth: [] }],
  body: Type.Optional(RefreshTokenBodySchema),
  response: {
    200: GenericActionResponseSchema,
  },
};

export const DeleteAccountRouteSchema = {
  description: 'GDPR / Mission LiFE compliant soft delete: scrubs PII, revokes tokens, anonymizes user record.',
  tags: ['Auth'],
  security: [{ bearerAuth: [] }],
  response: {
    200: GenericActionResponseSchema,
  },
};
