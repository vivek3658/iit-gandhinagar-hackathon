import type { FastifyReply, FastifyRequest } from 'fastify';
import type { AdminIdentity } from '../admin/admin.service';
import type { WasteScheduleQuery, WasteScheduleWrite } from './waste.schema';
import { WasteService } from './waste.service';

function isAdminIdentity(value: unknown): value is AdminIdentity {
  return typeof value === 'object' && value !== null &&
    'id' in value && typeof value.id === 'string' &&
    'email' in value && typeof value.email === 'string' &&
    'role' in value &&
    ['ADMIN', 'PROVIDER_ADMIN', 'CITY_ADMIN'].includes(String(value.role));
}

function isRuleError(error: unknown): boolean {
  return error instanceof Error && (
    error.message.includes('required') ||
    error.message.includes('outside') ||
    error.message.includes('effective dates') ||
    error.message.includes('weekdays') ||
    error.message.includes('overlaps') ||
    error.message.includes('inactive')
  );
}

export class WasteController {
  public static async listPublic(
    request: FastifyRequest<{ Querystring: WasteScheduleQuery }>,
    reply: FastifyReply,
  ) {
    try {
      return reply.send(await WasteService.listPublic(request.server.db, request.query));
    } catch (error: unknown) {
      request.log.error({ err: error }, 'Could not load waste collection schedule');
      return reply.serviceUnavailable('Waste collection schedules are unavailable.');
    }
  }

  public static async listForTenant(request: FastifyRequest, reply: FastifyReply) {
    const identity = request.user;
    if (!isAdminIdentity(identity)) return reply.forbidden('Administrator access is required.');
    try {
      return reply.send({ schedules: await WasteService.listForTenant(request.server.db, identity) });
    } catch (error: unknown) {
      if (isRuleError(error)) return reply.forbidden(error instanceof Error ? error.message : 'City admin access is required.');
      request.log.error({ err: error }, 'Could not load city waste schedules');
      return reply.serviceUnavailable('City waste schedules are unavailable.');
    }
  }

  public static async create(request: FastifyRequest, reply: FastifyReply) {
    const identity = request.user;
    if (!isAdminIdentity(identity)) return reply.forbidden('Administrator access is required.');
    try {
      const schedule = await WasteService.create(
        request.server.db,
        identity,
        request.body as WasteScheduleWrite,
      );
      return reply.status(201).send(schedule);
    } catch (error: unknown) {
      if (isRuleError(error)) return reply.badRequest(error instanceof Error ? error.message : 'Schedule is not valid.');
      request.log.error({ err: error }, 'Could not create waste schedule');
      return reply.serviceUnavailable('Waste schedule could not be saved.');
    }
  }

  public static async update(request: FastifyRequest, reply: FastifyReply) {
    const identity = request.user;
    if (!isAdminIdentity(identity)) return reply.forbidden('Administrator access is required.');
    const { scheduleId } = request.params as { scheduleId: string };
    try {
      const schedule = await WasteService.update(
        request.server.db,
        identity,
        scheduleId,
        request.body as WasteScheduleWrite,
      );
      if (!schedule) return reply.notFound('Waste schedule was not found in your tenant.');
      return reply.send(schedule);
    } catch (error: unknown) {
      if (isRuleError(error)) return reply.badRequest(error instanceof Error ? error.message : 'Schedule is not valid.');
      request.log.error({ err: error, scheduleId }, 'Could not update waste schedule');
      return reply.serviceUnavailable('Waste schedule could not be updated.');
    }
  }
}
