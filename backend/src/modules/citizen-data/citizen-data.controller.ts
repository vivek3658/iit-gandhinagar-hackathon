import type { FastifyReply, FastifyRequest } from 'fastify';
import type { CitizenDataService } from './citizen-data.service';
import type { TripBody, UtilityReadingBody, VehicleBody } from './citizen-data.schema';

export class CitizenDataController {
  public constructor(private readonly service: CitizenDataService) {}

  public listReadings = async (request: FastifyRequest, reply: FastifyReply) => {
    const readings = await this.service.listReadings(request.user.id);
    return reply.send({ readings });
  };

  public createReading = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
      const reading = await this.service.createReading(
        request.user.id,
        request.body as UtilityReadingBody,
      );
      return reply.code(201).send({ reading });
    } catch (error) {
      if (error instanceof Error) return reply.badRequest(error.message);
      throw error;
    }
  };

  public listVehicles = async (request: FastifyRequest, reply: FastifyReply) => {
    return reply.send({ vehicles: await this.service.listVehicles(request.user.id) });
  };

  public createVehicle = async (request: FastifyRequest, reply: FastifyReply) => {
    const vehicle = await this.service.createVehicle(request.user.id, request.body as VehicleBody);
    return reply.code(201).send({ vehicle });
  };

  public updateVehicle = async (request: FastifyRequest, reply: FastifyReply) => {
    const { vehicleId } = request.params as { vehicleId: string };
    const vehicle = await this.service.updateVehicle(
      request.user.id,
      vehicleId,
      request.body as VehicleBody,
    );
    if (!vehicle) return reply.notFound('Vehicle not found');
    return reply.send({ vehicle });
  };

  public deleteVehicle = async (request: FastifyRequest, reply: FastifyReply) => {
    const { vehicleId } = request.params as { vehicleId: string };
    const deleted = await this.service.deleteVehicle(request.user.id, vehicleId);
    if (!deleted) return reply.notFound('Vehicle not found');
    return reply.code(204).send();
  };

  public listTrips = async (request: FastifyRequest, reply: FastifyReply) => {
    return reply.send({ trips: await this.service.listTrips(request.user.id) });
  };

  public createTrip = async (request: FastifyRequest, reply: FastifyReply) => {
    try {
      const trip = await this.service.createTrip(request.user.id, request.body as TripBody);
      return reply.code(201).send({ trip });
    } catch (error) {
      if (error instanceof Error) return reply.badRequest(error.message);
      throw error;
    }
  };
}
