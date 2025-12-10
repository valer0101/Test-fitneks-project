import { Injectable, NotFoundException, ForbiddenException, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EventType, EventStatus } from '@prisma/client';
import { CreateEventDto } from './dto/create-event.dto';
import { UpdateEventDto } from './dto/update-event.dto';

@Injectable()
export class CalendarService {
  private readonly logger = new Logger(CalendarService.name);

  constructor(private readonly prisma: PrismaService) {}

  async getEvents(trainerId: number, month: number, year: number) {
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0, 23, 59, 59);

    const events = await this.prisma.event.findMany({
      where: {
        trainerId,
        date: {
          gte: startDate,
          lte: endDate,
        },
      },
      orderBy: {
        date: 'asc',
      },
    });

    return events;
  }

  async getEvent(eventId: string, trainerId: number) {
    const event = await this.prisma.event.findFirst({
      where: {
        id: eventId,
        trainerId,
      },
    });

    if (!event) {
      throw new NotFoundException('Event not found');
    }

    return event;
  }

  async createEvent(trainerId: number, data: CreateEventDto) {
    return this.prisma.event.create({
      data: {
        ...data,
        trainerId,
      },
    });
  }

  async updateEvent(eventId: string, trainerId: number, data: UpdateEventDto) {
    const event = await this.getEvent(eventId, trainerId);

    return this.prisma.event.update({
      where: {
        id: eventId,
      },
      data,
    });
  }

  async deleteEvent(eventId: string, trainerId: number) {
    const event = await this.getEvent(eventId, trainerId);

    return this.prisma.event.delete({
      where: {
        id: eventId,
      },
    });
  }

  async getEventsByDateRange(trainerId: number, startDate: Date, endDate: Date) {
    return this.prisma.event.findMany({
      where: {
        trainerId,
        date: {
          gte: startDate,
          lte: endDate,
        },
      },
      orderBy: {
        date: 'asc',
      },
    });
  }

  /**
   * Get events that a user has participated in (attended live streams)
   */
  async getUserAttendedEvents(userId: number): Promise<any[]> {
    this.logger.log(`Getting attended events for user ${userId}`);

    // Get all stream participations for this user
    const participations = await this.prisma.streamParticipation.findMany({
      where: {
        userId: userId,
      },
      include: {
        liveStream: {
          include: {
            event: true,
            trainer: {
              select: {
                id: true,
                displayName: true,
                username: true,
                profilePictureUrl: true,
              },
            },
          },
        },
      },
      orderBy: {
        joinedAt: 'desc',
      },
    });

    // Transform to event format with attendance info
    const attendedEvents = participations
      .filter(p => p.liveStream.event) // Only include if event exists
      .map(p => ({
        ...p.liveStream.event,
        attended: true,
        joinedAt: p.joinedAt,
        leftAt: p.leftAt,
        pointsEarned: {
          arms: p.armsEarned,
          chest: p.chestEarned,
          back: p.backEarned,
          abs: p.absEarned,
          legs: p.legsEarned,
          total: p.totalEarned,
        },
        trainer: p.liveStream.trainer,
      }));

    this.logger.log(`Found ${attendedEvents.length} attended events for user ${userId}`);

    return attendedEvents;
  }




/**
 * Get events that a learner has registered for (upcoming streams)
 */
async getLearnerRegisteredEvents(userId: number, month: number, year: number): Promise<any[]> {
  this.logger.log(`Getting registered events for user ${userId} for ${month}/${year}`);
  
  const startDate = new Date(year, month - 1, 1);
  const endDate = new Date(year, month, 0, 23, 59, 59);
  
  // Get all event registrations for this user in the date range
  const registrations = await this.prisma.eventRegistration.findMany({
    where: {
      userId: userId,
      event: {
        date: {
          gte: startDate,
          lte: endDate,
        },
        status: 'UPCOMING', // Only show upcoming events
      },
    },
    include: {
      event: {
        include: {
          trainer: {
            select: {
              id: true,
              displayName: true,
              username: true,
              profilePictureUrl: true,
            },
          },
        },
      },
    },
    orderBy: {
      event: {
        date: 'asc',
      },
    },
  });
  
  // Transform to event format with registration info
  const registeredEvents = registrations.map(r => ({
    ...r.event,
    registered: true,
    registeredAt: r.registeredAt,
  }));
  
  this.logger.log(`Found ${registeredEvents.length} registered events for user ${userId}`);
  
  return registeredEvents;
}





}