import { cookies } from 'next/headers';
import { NextRequest, NextResponse } from 'next/server';

type RouteContext = { params: Promise<{ path: string[] }> };

async function proxy(request: NextRequest, context: RouteContext) {
  const session = (await cookies()).get('urja_operator_session')?.value;
  if (!session) return NextResponse.json({ message: 'Sign in to continue.' }, { status: 401 });
  const apiRoot = process.env.URJA_API_URL;
  if (!apiRoot) return NextResponse.json({ message: 'URJA_API_URL is not configured.' }, { status: 503 });
  const { path } = await context.params;
  const allowed = path[0] === 'admin' || (path[0] === 'waste' && path[1] === 'admin') ||
    (path[0] === 'providers' && path.length === 2);
  if (!allowed) return NextResponse.json({ message: 'This operator API path is not available.' }, { status: 404 });
  const target = new URL(`${apiRoot.replace(/\/+$/, '')}/api/v1/${path.map(encodeURIComponent).join('/')}`);
  target.search = request.nextUrl.search;
  const headers = new Headers({
    authorization: `Bearer ${session}`,
    accept: 'application/json',
  });
  let body: string | undefined;
  if (request.method !== 'GET' && request.method !== 'HEAD') {
    body = await request.text();
    headers.set('content-type', request.headers.get('content-type') ?? 'application/json');
  }
  let upstream: Response;
  try {
    upstream = await fetch(target, {
      method: request.method,
      headers,
      body,
      cache: 'no-store',
    });
  } catch {
    return NextResponse.json({ message: 'The Urja backend is unreachable.' }, { status: 502 });
  }
  const content = await upstream.text();
  return new NextResponse(content, {
    status: upstream.status,
    headers: { 'content-type': upstream.headers.get('content-type') ?? 'application/json' },
  });
}

export const GET = proxy;
export const POST = proxy;
export const PUT = proxy;
