import type { FastifyReply, FastifyRequest } from 'fastify';
import { DevicesService } from './devices.service';
import type {
  LogHoursBody,
  RegisteredDeviceRuntimeBody,
  RegisterDeviceBody,
} from './devices.schema';

export class DevicesController {
  public constructor(private readonly service: DevicesService) {}

  public logHours = async (request: FastifyRequest, reply: FastifyReply): Promise<void> => {
    const user = request.user as { id: string };
    const result = await this.service.logDeviceHours(user.id, request.body as LogHoursBody);
    return reply.status(200).send(result);
  };

  public getSummary = async (request: FastifyRequest, reply: FastifyReply): Promise<void> => {
    const user = request.user as { id: string };
    const result = await this.service.getDeviceSummary(user.id);
    return reply.status(200).send(result);
  };

  public listRegistered = async (request: FastifyRequest, reply: FastifyReply): Promise<void> => {
    const user = request.user as { id: string };
    const devices = await this.service.listRegisteredDevices(user.id);
    const publicDevices = devices.map((device) => {
      const { userId: _userId, ...publicDevice } = device;
      void _userId;
      return publicDevice;
    });
    return reply.status(200).send({ devices: publicDevices });
  };

  public register = async (request: FastifyRequest, reply: FastifyReply): Promise<void> => {
    const user = request.user as { id: string };
    const device = await this.service.registerDevice(user.id, request.body as RegisterDeviceBody);
    const { userId: _userId, ...response } = device;
    void _userId;
    return reply.status(201).send({ device: response });
  };

  public removeRegistered = async (request: FastifyRequest, reply: FastifyReply): Promise<void> => {
    const user = request.user as { id: string };
    const { deviceId } = request.params as { deviceId: string };
    const removed = await this.service.removeRegisteredDevice(user.id, deviceId);
    if (!removed) {
      return reply.status(404).send({
        statusCode: 404,
        error: 'Not Found',
        message: 'Registered device was not found.',
      });
    }
    return reply.status(204).send();
  };

  public logRegisteredRuntime = async (
    request: FastifyRequest,
    reply: FastifyReply,
  ): Promise<void> => {
    const user = request.user as { id: string };
    const { deviceId } = request.params as { deviceId: string };
    const result = await this.service.logRegisteredRuntime(
      user.id,
      deviceId,
      request.body as RegisteredDeviceRuntimeBody,
    );
    if (!result) {
      return reply.status(404).send({
        statusCode: 404,
        error: 'Not Found',
        message: 'Registered device was not found.',
      });
    }
    return reply.status(200).send(result);
  };
}
