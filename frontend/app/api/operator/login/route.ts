import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  const apiRoot = process.env.URJA_API_URL;
  if (!apiRoot) {
    return NextResponse.json({ message: 'URJA_API_URL is not configured on the web server.' }, { status: 503 });
  }
  const body = await request.json() as { email?: string; password?: string };
  if (!body.email || !body.password) {
    return NextResponse.json({ message: 'Email and password are required.' }, { status: 400 });
  }
  let upstream: Response;
  try {
    upstream = await fetch(`${apiRoot.replace(/\/+$/, '')}/api/v1/admin/auth/login`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(body),
      cache: 'no-store',
    });
  } catch {
    return NextResponse.json({ message: 'The Urja backend is unreachable.' }, { status: 502 });
  }
  const result = await upstream.json() as {
    accessToken?: string;
    role?: string;
    tenantId?: string;
    tenantType?: string;
    message?: string;
  };
  if (!upstream.ok || !result.accessToken) {
    return NextResponse.json(
      { message: result.message ?? 'Login failed.' },
      { status: upstream.status },
    );
  }
  const response = NextResponse.json({
    role: result.role,
    tenantId: result.tenantId ?? null,
    tenantType: result.tenantType ?? null,
  });
  response.cookies.set('urja_operator_session', result.accessToken, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'strict',
    path: '/',
    maxAge: 15 * 60,
  });
  return response;
}
