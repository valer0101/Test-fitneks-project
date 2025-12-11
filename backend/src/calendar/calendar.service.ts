import { Injectable, NotFoundException, ForbiddenException, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EventType, EventStatus } from '@prisma/client';
import { CreateEventDto } from './dto/create-event.dto';
import { UpdateEventDto } from './dto/update-event.dto';
import { RedisEventsService } from '../notifications/redis-events.service';
import { InjectQueue } from '@nestjs/bull';
import type { Queue } from 'bull';

@Injectable()
export class CalendarService {
  private readonly logger = new Logger(CalendarService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redisEvents: RedisEventsService,  // ✅ ADD THIS
    @InjectQueue('notifications') private notificationQueue: Queue,  // ✅ ADD THIS
  ) {}

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
   * Register a learner for an event (add to calendar)
   */
  async registerForEvent(userId: number, eventId: string) {
    this.logger.log(`📅 Registering user ${userId} for event ${eventId}`);
    
    try {
      // 1. Get the event details
      const event = await this.prisma.event.findUnique({
        where: { id: eventId },
        include: {
          trainer: {
            select: { id: true, username: true, displayName: true },
          },
        },
      });

      if (!event) {
        throw new NotFoundException('Event not found');
      }

      if (event.status !== 'UPCOMING') {
        throw new ForbiddenException('Cannot register for non-upcoming events');
      }

      // 2. Create the registration
      const registration = await this.prisma.eventRegistration.upsert({
        where: {
          userId_eventId: {
            userId: userId,
            eventId: eventId,
          },
        },
        create: {
          userId: userId,
          eventId: eventId,
          status: 'registered',
        },
        update: {
          status: 'registered', // Re-register if previously cancelled
        },
      });

      // 3. Create/update notification preference (mark as eligible for notifications)
      await this.prisma.notificationPreference.upsert({
        where: {
          userId_trainerId: {
            userId: userId,
            trainerId: event.trainerId,
          },
        },
        create: {
          userId: userId,
          trainerId: event.trainerId,
          notifyOnLive: true,
          notifyOnReminders: true,
        },
        update: {
          notifyOnReminders: true, // Enable reminders
        },
      });

      this.logger.log(`✅ Notification preference updated for user ${userId} → trainer ${event.trainerId}`);

      // 4. Emit Redis event for registration
      await this.redisEvents.emit('event.registered', {
        userId: userId.toString(),
        eventId: eventId,
        trainerId: event.trainerId.toString(),
        trainerUsername: event.trainer.username,
        eventTitle: event.title,
        eventDate: event.date.toISOString(),
      });

      // 5. Schedule reminder notifications (1h and 10m before)
      const eventDate = new Date(event.date);
      const oneHourBefore = new Date(eventDate.getTime() - 60 * 60 * 1000);
      const tenMinutesBefore = new Date(eventDate.getTime() - 10 * 60 * 1000);
      const now = new Date();

      // Only schedule if the reminder time is in the future
      if (oneHourBefore > now) {
        await this.notificationQueue.add(
          'stream-reminder-1h',
          {
            eventId: eventId,
            trainerId: event.trainerId.toString(),
            userId: userId.toString(),
            title: event.title,
          },
          {
            delay: oneHourBefore.getTime() - now.getTime(),
            jobId: `reminder-1h-${eventId}-${userId}`, // Prevent duplicates
          }
        );
        this.logger.log(`⏰ Scheduled 1h reminder for user ${userId} at ${oneHourBefore.toISOString()}`);
      }

      if (tenMinutesBefore > now) {
        await this.notificationQueue.add(
          'stream-reminder-10m',
          {
            eventId: eventId,
            trainerId: event.trainerId.toString(),
            userId: userId.toString(),
            title: event.title,
          },
          {
            delay: tenMinutesBefore.getTime() - now.getTime(),
            jobId: `reminder-10m-${eventId}-${userId}`, // Prevent duplicates
          }
        );
        this.logger.log(`⏰ Scheduled 10m reminder for user ${userId} at ${tenMinutesBefore.toISOString()}`);
      }

      return {
        success: true,
        message: 'Registered for event and notifications scheduled',
        registration,
      };
    } catch (error) {
      this.logger.error('❌ Error registering for event:', error);
      throw error;
    }
  }

  /**
   * Unregister a learner from an event (remove from calendar)
   */
  async unregisterFromEvent(userId: number, eventId: string) {
    this.logger.log(`🗑️ Unregistering user ${userId} from event ${eventId}`);
    
    try {
      // 1. Update registration status to cancelled
      await this.prisma.eventRegistration.update({
        where: {
          userId_eventId: {
            userId: userId,
            eventId: eventId,
          },
        },
        data: {
          status: 'cancelled',
        },
      });

      // 2. Cancel scheduled reminder jobs
      const jobs = await this.notificationQueue.getJobs(['delayed']);
      for (const job of jobs) {
        const jobId = job.id?.toString() || '';
        if (jobId.includes(eventId) && jobId.includes(userId.toString())) {
          await job.remove();
          this.logger.log(`❌ Cancelled reminder job: ${jobId}`);
        }
      }

      // 3. Emit unregistration event
      await this.redisEvents.emit('event.unregistered', {
        userId: userId.toString(),
        eventId: eventId,
      });

      return {
        success: true,
        message: 'Unregistered from event and reminders cancelled',
      };
    } catch (error) {
      this.logger.error('❌ Error unregistering from event:', error);
      throw error;
    }
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