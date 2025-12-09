import { Injectable, OnModuleInit } from '@nestjs/common';
import { Process, Processor } from '@nestjs/bull';
import type { Job } from 'bull';  // ✅ Correct
import { PrismaService } from '../prisma/prisma.service';
import { RedisEventsService } from './redis-events.service';

@Injectable()
export class NotificationsService implements OnModuleInit {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redisEvents: RedisEventsService,
  ) {}

  async onModuleInit() {
    // ✅ Subscribe to Redis events
    await this.redisEvents.on('user.followed', (payload) => 
      this.handleUserFollowed(payload)
    );
    
    await this.redisEvents.on('stream.scheduled', (payload) => 
      this.handleStreamScheduled(payload)
    );
    
    await this.redisEvents.on('stream.live', (payload) => 
      this.handleStreamLive(payload)
    );
    
    console.log('✅ NotificationsService subscribed to Redis events');
  }

  async handleUserFollowed(payload: { 
    followerId: string; 
    followedUserId: string; 
    followerUsername: string;
  }) {
    console.log('🔔 User followed (via Redis):', payload);
    
    try {
      await this.prisma.notificationPreference.upsert({
        where: {
          userId_trainerId: {
            userId: parseInt(payload.followerId),
            trainerId: parseInt(payload.followedUserId),
          },
        },
        create: {
          userId: parseInt(payload.followerId),
          trainerId: parseInt(payload.followedUserId),
          notifyOnLive: true,
        },
        update: {
          notifyOnLive: true,
        },
      });
      
      console.log(`✅ Notification preference created: User ${payload.followerId} → Trainer ${payload.followedUserId}`);
    } catch (error) {
      console.error('❌ Error creating notification preference:', error);
    }
  }

  async handleStreamScheduled(payload: { 
    streamId: string; 
    trainerId: string; 
    title: string;
    scheduledAt: Date;
  }) {
    console.log('📅 Stream SCHEDULED (via Redis):', payload);
    
    try {
      const notificationPrefs = await this.prisma.notificationPreference.findMany({
        where: {
          trainerId: parseInt(payload.trainerId),
          notifyOnLive: true,
        },
        include: {
          user: {
            select: { id: true, username: true, displayName: true },
          },
        },
      });
      
      console.log(`📢 Found ${notificationPrefs.length} followers to notify about SCHEDULED stream: ${payload.title}`);
      
      for (const pref of notificationPrefs) {
        console.log(`📱 Would notify: ${pref.user.displayName || pref.user.username} - "New stream scheduled: ${payload.title}"`);
        // TODO Phase 2: Send actual push notification
      }
    } catch (error) {
      console.error('❌ Error processing scheduled stream notifications:', error);
    }
  }

  async handleStreamLive(payload: { 
    streamId: string; 
    trainerId: string; 
    title: string;
  }) {
    console.log('🔴 Stream LIVE (via Redis):', payload);
    
    try {
      const notificationPrefs = await this.prisma.notificationPreference.findMany({
        where: {
          trainerId: parseInt(payload.trainerId),
          notifyOnLive: true,
        },
        include: {
          user: {
            select: { id: true, username: true, displayName: true },
          },
        },
      });
      
      console.log(`📢 Found ${notificationPrefs.length} followers to notify that stream is LIVE: ${payload.title}`);
      
      for (const pref of notificationPrefs) {
        console.log(`📱 Would notify: ${pref.user.displayName || pref.user.username} - "Stream is LIVE NOW: ${payload.title}"`);
        // TODO Phase 2: Send actual push notification
      }
    } catch (error) {
      console.error('❌ Error processing live stream notifications:', error);
    }
  }
}

// ✅ Processor for handling scheduled reminder jobs from BullMQ
@Processor('notifications')
export class NotificationProcessor {
  constructor(private readonly prisma: PrismaService) {}

  @Process('stream-reminder-1h')
  async handleOneHourReminder(job: Job) {
    const { streamId, trainerId, title } = job.data;
    console.log('⏰ Processing 1-hour reminder job:', job.data);
    
    try {
      const notificationPrefs = await this.prisma.notificationPreference.findMany({
        where: {
          trainerId: parseInt(trainerId),
          notifyOnLive: true,
        },
        include: {
          user: {
            select: { id: true, username: true, displayName: true },
          },
        },
      });
      
      console.log(`📢 Sending 1h reminder to ${notificationPrefs.length} followers`);
      
      for (const pref of notificationPrefs) {
        console.log(`📱 Would notify: ${pref.user.displayName || pref.user.username} - "${title} starts in 1 hour!"`);
        // TODO Phase 2: Send actual push notification
      }
    } catch (error) {
      console.error('❌ Error processing 1h reminder:', error);
      throw error; // Re-throw so BullMQ can retry
    }
  }

  @Process('stream-reminder-10m')
  async handleTenMinuteReminder(job: Job) {
    const { streamId, trainerId, title } = job.data;
    console.log('⏰ Processing 10-minute reminder job:', job.data);
    
    try {
      const notificationPrefs = await this.prisma.notificationPreference.findMany({
        where: {
          trainerId: parseInt(trainerId),
          notifyOnLive: true,
        },
        include: {
          user: {
            select: { id: true, username: true, displayName: true },
          },
        },
      });
      
      console.log(`📢 Sending 10m reminder to ${notificationPrefs.length} followers`);
      
      for (const pref of notificationPrefs) {
        console.log(`📱 Would notify: ${pref.user.displayName || pref.user.username} - "${title} starts in 10 minutes!"`);
        // TODO Phase 2: Send actual push notification
      }
    } catch (error) {
      console.error('❌ Error processing 10m reminder:', error);
      throw error; // Re-throw so BullMQ can retry
    }
  }
}