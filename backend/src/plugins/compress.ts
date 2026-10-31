import compress from '@fastify/compress';
import fp from 'fastify-plugin';
import zlib from 'node:zlib';

export default fp(async (fastify) => {
  await fastify.register(compress, {
    global: true,
    threshold: 1024, // Only compress responses larger than 1 KB to prevent CPU overhead on tiny payloads
    encodings: ['br', 'gzip', 'deflate'],
    brotliOptions: {
      params: {
        [zlib.constants.BROTLI_PARAM_QUALITY]: 4, // Fast dynamic compression level (optimal for API throughput)
      },
    },
    zlibOptions: {
      level: 6, // Standard gzip compression level
    },
  });
});
