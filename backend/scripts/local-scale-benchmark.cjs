const http = require('node:http');
const os = require('node:os');
const path = require('node:path');
const { spawn } = require('node:child_process');
const { performance } = require('node:perf_hooks');

const args = Object.fromEntries(
  process.argv.slice(2).map((arg) => {
    const [key, value] = arg.replace(/^--/, '').split('=');
    return [key, Number(value)];
  }),
);
const maxInstances = args.instances || 6;
const durationSeconds = args.duration || 10;
const warmupSeconds = args.warmup || 2;
const connections = args.connections || 40;
const repeats = args.repeats || 3;
const firstPort = 3101;
const ports = Array.from({ length: maxInstances }, (_, index) => firstPort + index);
const children = [];
const agent = new http.Agent({ keepAlive: true, maxSockets: connections });

function send(method, pathname, port, payload, headers = {}) {
  return new Promise((resolve, reject) => {
    const body = payload === undefined ? undefined : Buffer.from(JSON.stringify(payload));
    const request = http.request(
      {
        host: '127.0.0.1',
        port,
        path: pathname,
        method,
        agent,
        timeout: 5000,
        headers: {
          ...(body ? { 'content-type': 'application/json', 'content-length': body.length } : {}),
          ...headers,
        },
      },
      (response) => {
        const chunks = [];
        response.on('data', (chunk) => chunks.push(chunk));
        response.on('end', () => resolve({ statusCode: response.statusCode, body: Buffer.concat(chunks).toString() }));
      },
    );
    request.on('timeout', () => request.destroy(new Error('request timeout')));
    request.on('error', reject);
    if (body) request.write(body);
    request.end();
  });
}

async function waitForServer(port, child) {
  const deadline = Date.now() + 30000;
  while (Date.now() < deadline) {
    if (child.exitCode !== null) {
      throw new Error(`API process on port ${port} exited with code ${child.exitCode}`);
    }
    try {
      if ((await send('GET', '/health', port)).statusCode === 200) return;
    } catch {
      await new Promise((resolve) => setTimeout(resolve, 250));
    }
  }
  throw new Error(`API process on port ${port} did not become healthy within 30 seconds`);
}

async function benchmark(activePorts, seconds, makeRequest) {
  const latencies = [];
  let failures = 0;
  let requestIndex = 0;
  const start = performance.now();
  const deadline = start + seconds * 1000;

  async function worker() {
    while (performance.now() < deadline) {
      const port = activePorts[requestIndex++ % activePorts.length];
      const requestStart = performance.now();
      try {
        if ((await makeRequest(port)).statusCode !== 200) failures++;
      } catch {
        failures++;
      } finally {
        latencies.push(performance.now() - requestStart);
      }
    }
  }

  await Promise.all(Array.from({ length: connections }, () => worker()));
  const elapsedMs = performance.now() - start;
  latencies.sort((left, right) => left - right);
  const percentile = (fraction) => latencies[Math.max(0, Math.ceil(latencies.length * fraction) - 1)] || 0;

  return {
    requests: latencies.length,
    requestsPerSecond: latencies.length / (elapsedMs / 1000),
    p50Ms: percentile(0.5),
    p95Ms: percentile(0.95),
    p99Ms: percentile(0.99),
    failures,
  };
}

function median(values) {
  const sorted = [...values].sort((left, right) => left - right);
  return sorted[Math.floor(sorted.length / 2)];
}

async function main() {
  const serverPath = path.join(__dirname, '..', 'dist', 'server.js');
  for (const port of ports) {
    try {
      const response = await send('GET', '/health', port);
      if (response.statusCode === 200) {
        throw new Error(`Port ${port} is already serving HTTP; stop that process and retry`);
      }
    } catch (error) {
      if (error.message.includes('already serving')) throw error;
    }
  }

  for (const port of ports) {
    const child = spawn(process.execPath, [serverPath], {
      cwd: path.join(__dirname, '..'),
      stdio: 'ignore',
      env: {
        ...process.env,
        NODE_ENV: 'test',
        HOST: '127.0.0.1',
        PORT: String(port),
        LOG_LEVEL: 'fatal',
        JWT_SECRET: 'local-benchmark-only-secret-32-characters-minimum',
        DATABASE_URL: '',
        REDIS_URL: '',
        MONGODB_URL: '',
        RABBITMQ_URL: '',
      },
    });
    children.push(child);
    await waitForServer(port, child);
  }

  console.log(`Host: ${os.cpus()[0].model}; logical CPUs: ${os.cpus().length}; RAM: ${(os.totalmem() / 1024 ** 3).toFixed(1)} GiB`);
  const tokens = new Map();
  for (const port of ports) {
    const login = await send('POST', '/api/v1/auth/google', port, { idToken: `mock_test_token_${port}` });
    if (login.statusCode !== 200) {
      throw new Error(`Could not create benchmark user on port ${port}: HTTP ${login.statusCode}`);
    }
    tokens.set(port, JSON.parse(login.body).accessToken);
  }

  const workloads = [
    { name: 'GET /health', makeRequest: (port) => send('GET', '/health', port) },
    {
      name: 'POST /api/v1/mascot/interact',
      makeRequest: (port) =>
        send('POST', '/api/v1/mascot/interact', port, { action: 'PET' }, {
          authorization: `Bearer ${tokens.get(port)}`,
        }),
    },
  ];

  console.log(`Workloads: GET /health and authenticated POST /api/v1/mascot/interact; ${connections} concurrent clients; ${durationSeconds}s per measured run; ${repeats} runs per size; round-robin to local processes.`);
  console.log('Instances | Workload                         | Median req/s | p50 ms | p95 ms | p99 ms | Errors | Requests/run');

  for (let size = 1; size <= maxInstances; size++) {
    const activePorts = ports.slice(0, size);
    for (const workload of workloads) {
      await benchmark(activePorts, warmupSeconds, workload.makeRequest);
      const samples = [];
      for (let repeat = 0; repeat < repeats; repeat++) {
        samples.push(await benchmark(activePorts, durationSeconds, workload.makeRequest));
      }
      const result = {
        instances: size,
        requestsPerSecond: median(samples.map((sample) => sample.requestsPerSecond)),
        p50Ms: median(samples.map((sample) => sample.p50Ms)),
        p95Ms: median(samples.map((sample) => sample.p95Ms)),
        p99Ms: median(samples.map((sample) => sample.p99Ms)),
        failures: samples.reduce((sum, sample) => sum + sample.failures, 0),
        requestsPerRun: median(samples.map((sample) => sample.requests)),
      };
      console.log(
        `${String(result.instances).padStart(9)} | ${workload.name.padEnd(32)} | ${result.requestsPerSecond.toFixed(1).padStart(12)} | ${result.p50Ms.toFixed(2).padStart(6)} | ${result.p95Ms.toFixed(2).padStart(6)} | ${result.p99Ms.toFixed(2).padStart(6)} | ${String(result.failures).padStart(6)} | ${result.requestsPerRun}`,
      );
    }
  }

  console.log('Caveat: single-host local HTTP comparison only; the generator and API share host resources. The write route uses per-process in-memory state. This does not model Docker limits, a load balancer, shared database, production traffic, or a 1-vCPU / 2-GiB instance.');
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    agent.destroy();
    await Promise.all(children.map((child) => new Promise((resolve) => {
      if (child.exitCode !== null || child.signalCode !== null) return resolve();
      child.once('exit', resolve);
      child.kill();
    })));
  });