import { Injectable, HttpException, HttpStatus, Logger, 
  NotFoundException, 
  UnauthorizedException,
  BadRequestException,
  InternalServerErrorException,
  ForbiddenException } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bull';  // ✅ ADD THIS
import type { Queue } from 'bull';  // ✅ Correct
import { RedisEventsService } from '../notifications/redis-events.service';  // ✅ ADD THIS

import { EventEmitter2 } from '@nestjs/event-emitter';
import { PrismaService } from '../prisma/prisma.service';
import { CreateLivestreamDto } from './dto/create-livestream.dto';
import { LiveStream, LiveStreamStatus, Prisma, EventType, EventStatus } from '@prisma/client';  // ✅ Add EventType, EventStatus
import { AccessToken } from 'livekit-server-sdk';
import { livekitConfig } from '../config/livekit.config';
import * as livekit from 'livekit-server-sdk';
import { RoomServiceClient, TrackSource } from 'livekit-server-sdk';
import { ConfigService } from '@nestjs/config';  // ✅ Add this import




@Injectable()
export class LivestreamsService {
  private readonly logger = new Logger(LivestreamsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redisEvents: RedisEventsService,  // ✅ CHANGE from EventEmitter2
    @InjectQueue('notifications') private notificationQueue: Queue,  // ✅ ADD THIS
    private configService: ConfigService,
  ) {}

  /**
   * Create a new livestream with optional recurring streams
   * Muscle points represent both intensity and earnable points (0-5 scale)
   */
  async createLivestream(dto: CreateLivestreamDto, trainerId: number): Promise<LiveStream> {
  try {
    // ✅ Step 1: Calculate scheduledDate FIRST
    let scheduledDate: Date;

    if (dto.goLiveNow) {
      scheduledDate = new Date();
      this.logger.log('🔴 GOING LIVE NOW - using current time');
    } else {
      scheduledDate = new Date(dto.scheduledAt);
      const now = new Date();
      const fiveMinutesFromNow = new Date(now.getTime() + 5 * 60 * 1000);
      
      if (scheduledDate < fiveMinutesFromNow) {
        throw new HttpException(
          'Scheduled streams must be at least 5 minutes in the future',
          HttpStatus.BAD_REQUEST,
        );
      }
      this.logger.log('📅 Scheduled stream - validated 5-minute rule');
    }

    // ✅ Step 2: Calculate total points
    const totalPossiblePoints = 
      dto.musclePoints.arms +
      dto.musclePoints.chest +
      dto.musclePoints.back +
      dto.musclePoints.abs +
      dto.musclePoints.legs;

    // ✅ Step 3: Create the primary livestream
    const primaryStream = await this.prisma.liveStream.create({
      data: {
        title: dto.title,
        description: dto.description,
        status: dto.goLiveNow ? LiveStreamStatus.LIVE : LiveStreamStatus.SCHEDULED,
        visibility: dto.visibility,
        scheduledAt: scheduledDate,
        maxParticipants: dto.maxParticipants,
        isRecurring: dto.isRecurring,
        equipmentNeeded: dto.equipmentNeeded,
        workoutStyle: dto.workoutStyle,
        giftRequirement: dto.giftRequirement,
        musclePoints: dto.musclePoints as Prisma.InputJsonValue,
        totalPossiblePoints: totalPossiblePoints,
        trainerId: trainerId,
      },
    });

    // ✅ Step 4: Create corresponding Event for calendar
    const event = await this.prisma.event.create({
      data: {
        title: dto.title,
        description: dto.description,
        date: scheduledDate,
        trainerId: trainerId,
        type: EventType.CLASS,
        status: EventStatus.UPCOMING,
        trainingType: dto.workoutStyle,
        equipment: dto.equipmentNeeded.map(e =>
          e.toString()
            .replace(/_/g, ' ')
            .toLowerCase()
            .split(' ')
            .map(word => word.charAt(0).toUpperCase() + word.slice(1))
            .join(' ')
        ),
        pointsBreakdown: dto.musclePoints as Prisma.InputJsonValue,
        maxParticipants: dto.maxParticipants,
        duration: 60,
        ticketValue: dto.giftRequirement > 0 ? dto.giftRequirement : null,
      },
    });

    // Link the LiveStream to the Event
    await this.prisma.liveStream.update({
      where: { id: primaryStream.id },
      data: { eventId: event.id },
    });

    // ✅ Step 5: Create recurring streams if needed
    if (dto.isRecurring) {
      const recurringStreams: Prisma.LiveStreamCreateManyInput[] = [];
      const oneWeekMs = 7 * 24 * 60 * 60 * 1000;
      
      for (let i = 1; i <= 3; i++) {
        const recurringDate = new Date(scheduledDate.getTime() + (i * oneWeekMs));
        
        const recurringEvent = await this.prisma.event.create({
          data: {
            title: dto.title,
            description: dto.description,
            date: recurringDate,
            trainerId: trainerId,
            type: EventType.CLASS,
            status: EventStatus.UPCOMING,
            trainingType: dto.workoutStyle,
            equipment: dto.equipmentNeeded.map(e =>  
              e.toString()
                .replace(/_/g, ' ')
                .toLowerCase()
                .split(' ')
                .map(word => word.charAt(0).toUpperCase() + word.slice(1))
                .join(' ')
            ),
            pointsBreakdown: dto.musclePoints as Prisma.InputJsonValue,
            maxParticipants: dto.maxParticipants,
            duration: 60,
            ticketValue: dto.giftRequirement > 0 ? dto.giftRequirement : null,
          },
        });
        
        recurringStreams.push({
          title: dto.title,
          description: dto.description,
          status: LiveStreamStatus.SCHEDULED,
          visibility: dto.visibility,
          scheduledAt: recurringDate,
          maxParticipants: dto.maxParticipants,
          isRecurring: false,
          equipmentNeeded: dto.equipmentNeeded,
          workoutStyle: dto.workoutStyle,
          giftRequirement: dto.giftRequirement,
          musclePoints: dto.musclePoints as Prisma.InputJsonValue,
          totalPossiblePoints: totalPossiblePoints,
          trainerId: trainerId,
          parentStreamId: primaryStream.id,
          eventId: recurringEvent.id,
        });
      }

      await this.prisma.liveStream.createMany({
        data: recurringStreams,
      });
      
      this.logger.log(`Created ${recurringStreams.length} recurring streams for stream ${primaryStream.id}`);
    }

    // ✅ Step 6: NOW emit Redis events (AFTER primaryStream is created)
    if (dto.goLiveNow) {
      // Going live immediately
      await this.redisEvents.emit('stream.live', {
        streamId: primaryStream.id,
        trainerId: trainerId.toString(),
        title: primaryStream.title,
      });
      
      this.logger.log(`🔴 Stream going LIVE NOW - Redis event published`);
    } else {
      // Scheduled for future
      await this.redisEvents.emit('stream.scheduled', {
        streamId: primaryStream.id,
        trainerId: trainerId.toString(),
        title: primaryStream.title,
        scheduledAt: primaryStream.scheduledAt,
      });
      
      this.logger.log(`📅 Stream SCHEDULED - Redis event published`);
      
      // Schedule reminder jobs using BullMQ
      const scheduledTime = new Date(dto.scheduledAt).getTime();
      const now = Date.now();
      
      const oneHourDelay = scheduledTime - now - (60 * 60 * 1000);
      const tenMinDelay = scheduledTime - now - (10 * 60 * 1000);
      
      // Only schedule if delays are positive (stream is in the future)
      if (oneHourDelay > 0) {
        await this.notificationQueue.add(
          'stream-reminder-1h',
          {
            streamId: primaryStream.id,
            trainerId: trainerId.toString(),
            title: primaryStream.title,
          },
          {
            delay: oneHourDelay,
            attempts: 3,
            backoff: { type: 'exponential', delay: 60000 },
          }
        );
        this.logger.log(`⏰ Scheduled 1-hour reminder for stream ${primaryStream.id}`);
      }
      
      if (tenMinDelay > 0) {
        await this.notificationQueue.add(
          'stream-reminder-10m',
          {
            streamId: primaryStream.id,
            trainerId: trainerId.toString(),
            title: primaryStream.title,
          },
          {
            delay: tenMinDelay,
            attempts: 3,
            backoff: { type: 'exponential', delay: 60000 },
          }
        );
        this.logger.log(`⏰ Scheduled 10-minute reminder for stream ${primaryStream.id}`);
      }
    }

    // Log muscle points distribution
    this.logger.log(`Stream ${primaryStream.id} created with muscle points: ${JSON.stringify(dto.musclePoints)}`);
    this.logger.log(`Total possible points for learners: ${totalPossiblePoints}`);
    
    return primaryStream;
    
  } catch (error) {
    this.logger.error('Error creating livestream', error.stack);
    
    if (error instanceof HttpException) {
      throw error;
    }
    
    throw new HttpException(
      'An error occurred while creating the livestream',
      HttpStatus.INTERNAL_SERVER_ERROR,
    );
  }
}



async getLivestreamByEventId(eventId: string): Promise<any> {
  return this.prisma.liveStream.findFirst({
    where: { eventId: eventId },
    include: {
      trainer: {
        select: {
          id: true,
          username: true,
          displayName: true,
          profilePictureUrl: true,
          xp: true,
        },
      },
    },
  });
}



async getLivestream(id: string): Promise<any> {
  return this.prisma.liveStream.findUnique({
    where: { id },
    include: {
      trainer: {
        select: {
          id: true,
          username: true,
          displayName: true,
          profilePictureUrl: true,
          xp: true,
        },
      },
    },
  });
}

async updateLivestream(id: string, dto: CreateLivestreamDto): Promise<LiveStream> {
  // Calculate total points
  const totalPossiblePoints = Object.values(dto.musclePoints as Record<string, number>)
    .reduce((sum: number, points: number) => sum + points, 0);

  return this.prisma.liveStream.update({
    where: { id },
    data: {
      title: dto.title,
      description: dto.description,
      visibility: dto.visibility,
      scheduledAt: new Date(dto.scheduledAt),
      maxParticipants: dto.maxParticipants,
      equipmentNeeded: dto.equipmentNeeded,
      workoutStyle: dto.workoutStyle,
      giftRequirement: dto.giftRequirement,
      musclePoints: dto.musclePoints as Prisma.InputJsonValue,
      totalPossiblePoints: totalPossiblePoints,
    },
  });
}

async updateLinkedEvent(eventId: string, dto: CreateLivestreamDto): Promise<void> {
  await this.prisma.event.update({
    where: { id: eventId },
    data: {
      title: dto.title,
      description: dto.description,
      date: new Date(dto.scheduledAt),
      trainingType: dto.workoutStyle.toString(),
      equipment: dto.equipmentNeeded.map(e =>  
          e.toString()
          .replace(/_/g, ' ')  // ✅ Replace underscores with spaces
          .toLowerCase()
          .split(' ')
          .map(word => word.charAt(0).toUpperCase() + word.slice(1))
          .join(' ')
      ),
      pointsBreakdown: dto.musclePoints as Prisma.InputJsonValue,
      maxParticipants: dto.maxParticipants,
      ticketValue: dto.giftRequirement > 0 ? dto.giftRequirement : null,
    },
  });
}



// LiveKit 

/**
 * Get livestream by ID
 */
async getLivestreamById(id: string): Promise<any> {
  return this.prisma.liveStream.findUnique({
    where: { id },
    include: {
      trainer: {
        select: {
          id: true,
          username: true,
          displayName: true,
          profilePictureUrl: true,
          xp: true,  // ✅ ADD THIS LINE

        },
      },
    },
  });
}

/**
 * Generate LiveKit access token
 */
async generateLiveKitToken(
  userId: string,
  roomName: string,
  userName: string,
  isOwner: boolean,
): Promise<string> {
  try {
    const at = new AccessToken(
      livekitConfig.apiKey,
      livekitConfig.apiSecret,
      {
        identity: userId,
        name: userName,
      }
    );

    // Grant permissions
    at.addGrant({
      roomJoin: true,
      room: roomName,
      canPublish: isOwner, // Only trainer can publish video/audio
      canPublishData: true, // Everyone can send chat messages
      canSubscribe: true,
    });

// ✅ ADD THIS: Include metadata for role identification
const metadata = {
  userId: userId.replace('trainer_', '').replace('learner_', ''),
  role: userId.startsWith('trainer_') ? 'trainer' : 'learner',
  userName: userName,
};

at.metadata = JSON.stringify(metadata);




    return at.toJwt();
  } catch (error) {
    this.logger.error('Failed to generate LiveKit token', error.stack);
    throw new HttpException(
      'Failed to generate access token',
      HttpStatus.INTERNAL_SERVER_ERROR,
    );
  }
}





/**
 * Join a livestream as trainer or learner
 * Handles role detection, gift requirements, and permission levels
 */
async joinLivestream(livestreamId: string, userId: number) {
  // ✅ Generate unique request ID for tracking
  const requestId = Math.random().toString(36).substring(7);
  
  this.logger.log(`🔵 [${requestId}] ===== JOIN REQUEST START =====`);
  this.logger.log(`🔵 [${requestId}] User ${userId} attempting to join stream ${livestreamId}`);
  this.logger.log(`🔵 [${requestId}] User type: ${typeof userId}, Stream type: ${typeof livestreamId}`);

  // ✅ BAN CHECK - FIRST THING BEFORE ANYTHING ELSE
  this.logger.log(`🔍 [${requestId}] Checking ban status...`);
  
  const isBanned = await this.prisma.bannedStreamParticipant.findUnique({
    where: {
      livestreamId_userId: {
        livestreamId,
        userId,
      },
    },
  });
  
  this.logger.log(`🔍 [${requestId}] Ban check result: ${isBanned ? 'BANNED' : 'NOT BANNED'}`);
  if (isBanned) {
    this.logger.log(`🔍 [${requestId}] Ban details: ${JSON.stringify(isBanned)}`);
  }
  
  if (isBanned) {
    this.logger.error(`🚫 [${requestId}] ===== BANNED USER BLOCKED =====`);
    this.logger.error(`🚫 [${requestId}] User ${userId} is BANNED from stream ${livestreamId}`);
    this.logger.error(`🚫 [${requestId}] Throwing ForbiddenException...`);
    
    throw new ForbiddenException(
      'You have been removed from this livestream and cannot rejoin.',
    );
  }
  
  this.logger.log(`✅ [${requestId}] Ban check passed - user is NOT banned`);
  
  // Step 1: Get the livestream with trainer and gifts info
  this.logger.log(`📋 [${requestId}] Fetching livestream details...`);
  const livestream = await this.prisma.liveStream.findUnique({
    where: { id: livestreamId },
    include: {
      trainer: {
        select: {
          id: true,
          username: true,
          displayName: true,
          profilePictureUrl: true,
        },
      },
    }
  });

  // Step 2: Validation - stream must exist
  if (!livestream) {
    this.logger.error(`❌ [${requestId}] Livestream not found`);
    throw new HttpException(
      'Livestream not found',
      HttpStatus.NOT_FOUND,
    );
  }
  
  this.logger.log(`✅ [${requestId}] Livestream found: ${livestream.title}`);

  // Step 3: Get user details
  this.logger.log(`👤 [${requestId}] Fetching user details...`);
  const user = await this.prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      username: true,
      displayName: true,
    },
  });

  if (!user) {
    this.logger.error(`❌ [${requestId}] User not found`);
    throw new HttpException(
      'User not found',
      HttpStatus.NOT_FOUND,
    );
  }
  
  this.logger.log(`✅ [${requestId}] User found: ${user.displayName || user.username}`);

  // Step 4: Check if user IS the trainer
  if (livestream.trainerId === userId) {
  this.logger.log(`🎯 [${requestId}] User is the TRAINER - granting full permissions`);
  
  // ✅ ADD THIS: If stream was scheduled, update to LIVE and notify
  if (livestream.status === LiveStreamStatus.SCHEDULED) {
    await this.prisma.liveStream.update({
      where: { id: livestreamId },
      data: { status: LiveStreamStatus.LIVE },
    });
    
    this.logger.log(`🔴 [${requestId}] Stream status updated to LIVE`);
    
    // ✅ Emit LIVE notification via Redis
    await this.redisEvents.emit('stream.live', {
      streamId: livestream.id,
      trainerId: userId.toString(),
      title: livestream.title,
    });
    
    this.logger.log(`🔔 [${requestId}] Stream LIVE notification published to Redis`);
  }
    const trainerToken = await this.generateLiveKitToken(
      `trainer_${userId}`,
      livestream.id,
      user.displayName || user.username,
      true,
    );
    
    this.logger.log(`✅ [${requestId}] ===== TRAINER JOIN SUCCESS =====`);
    
    return {
      token: trainerToken,
      roomName: livestream.id,
      isOwner: true,
      livestream: {
        id: livestream.id,
        title: livestream.title,
        trainer: livestream.trainer,
      },
    };
  }

  // Step 5: LEARNER PATH - Check gift requirements
  this.logger.log(`🎓 [${requestId}] User is a LEARNER - checking gift requirements`);
  const giftRequirement = livestream.giftRequirement || 0;
  
  if (giftRequirement > 0) {
    this.logger.log(`🎁 [${requestId}] Gift requirement: ${giftRequirement} Protein Bars`);
    
    const sentGifts = await this.prisma.livestreamGift.count({
      where: {
        senderId: userId,
        livestreamId: livestreamId,
        giftType: 'PROTEIN_BAR',
      }
    });
    
    this.logger.log(`🎁 [${requestId}] User has sent: ${sentGifts} Protein Bars`);
    
    if (sentGifts < giftRequirement) {
      this.logger.warn(`⛔ [${requestId}] Insufficient gifts - blocking join`);
      throw new HttpException(
        `You must send ${giftRequirement} Protein Bar(s) to join this stream. You've sent ${sentGifts}.`,
        HttpStatus.FORBIDDEN,
      );
    }
    
    this.logger.log(`✅ [${requestId}] Gift requirement satisfied`);
  }

  // Step 6: Generate LIMITED token for learner
  this.logger.log(`🔑 [${requestId}] Generating LIMITED token for learner`);
  const learnerToken = await this.generateLiveKitToken(
    `learner_${userId}`,
    livestream.id,
    user.displayName || user.username,
    false,
  );

  // Step 7: Record participation when learner joins
  this.logger.log(`📝 [${requestId}] Recording participation...`);
  await this.recordParticipation(livestreamId, userId);

  this.logger.log(`✅ [${requestId}] ===== LEARNER JOIN SUCCESS =====`);

  return {
    token: learnerToken,
    roomName: livestream.id,
    isOwner: false,
    livestream: {
      id: livestream.id,
      title: livestream.title,
      description: livestream.description,
      trainer: livestream.trainer,
      giftRequirement: livestream.giftRequirement,
      musclePoints: livestream.musclePoints,
    },
  };
}


/**
 * Grant video publishing permission to a learner
 * Called when trainer approves a learner's request to join on camera
 */
async grantVideoPermission(
  livestreamId: string,
  learnerId: string,      // Format: "learner_123"
  trainerId: number,
) {
  this.logger.log(`Trainer ${trainerId} granting permission to ${learnerId} in stream ${livestreamId}`);
  
  // Step 1: Verify requester is actually the trainer
  const livestream = await this.prisma.liveStream.findUnique({
    where: { id: livestreamId },
    select: {
      id: true,
      trainerId: true,
    },
  });
  
  if (!livestream) {
    throw new HttpException(
      'Livestream not found',
      HttpStatus.NOT_FOUND,
    );
  }
  
  if (livestream.trainerId !== trainerId) {
    throw new HttpException(
      'Only the trainer can grant video permissions',
      HttpStatus.FORBIDDEN,
    );
  }
  
  // Step 2: Extract user ID from "learner_123" format
  const learnerIdNum = parseInt(learnerId.replace('learner_', ''));
  
  if (isNaN(learnerIdNum)) {
    throw new HttpException(
      'Invalid learner ID format',
      HttpStatus.BAD_REQUEST,
    );
  }
  
  // Step 3: Get learner details
  const learner = await this.prisma.user.findUnique({
    where: { id: learnerIdNum },
    select: {
      id: true,
      username: true,
      displayName: true,
    },
  });
  
  if (!learner) {
    throw new HttpException(
      'Learner not found',
      HttpStatus.NOT_FOUND,
    );
  }
  
  // Step 4: Generate NEW token with canPublish: true
  this.logger.log(`Generating upgraded token with video permission for ${learnerId}`);
  
  const newToken = await this.generateLiveKitToken(
    learnerId,  // Keep same identity
    livestream.id,
    learner.displayName || learner.username,
    true,  // NOW they can publish!
  );
  
  this.logger.log(`Successfully granted video permission to ${learnerId}`);
  
  return { 
    token: newToken, 
    learnerId,
    success: true,
  };
}



/**
 * Update stream status
 */
async updateStreamStatus(id: string, status: LiveStreamStatus): Promise<void> {
  await this.prisma.liveStream.update({
    where: { id },
    data: { status },
  });
  
  this.logger.log(`Updated stream ${id} status to ${status}`);
}




/**
 * Get user by ID
 */
async getUserById(userId: number): Promise<any> {
  return this.prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      username: true,
      displayName: true,
      profilePictureUrl: true,
    },
  });
}




/**
 * Record learner participation when they join a stream
 */
async recordParticipation(livestreamId: string, learnerId: number): Promise<void> {
  this.logger.log(`Recording participation for learner ${learnerId} in stream ${livestreamId}`);
  
  // Check if participation already exists
  const existing = await this.prisma.streamParticipation.findUnique({
    where: {
      userId_liveStreamId: {
        userId: learnerId,
        liveStreamId: livestreamId,
      },
    },
  });
  
  if (!existing) {
    // Create new participation record
    await this.prisma.streamParticipation.create({
      data: {
        userId: learnerId,
        liveStreamId: livestreamId,
        joinedAt: new Date(),
        participationPct: 0,
        pointsCredited: false,
      },
    });
    
    this.logger.log(`✅ Participation recorded for learner ${learnerId}`);
  } else {
    this.logger.log(`ℹ️ Participation already exists for learner ${learnerId}`);
  }
}






/**
 * End a livestream
 * Updates status to ENDED and notifies all participants
 */
async endLivestream(livestreamId: string, trainerId: number): Promise<void> {
  this.logger.log(`Trainer ${trainerId} ending stream ${livestreamId}`);
  
  // Step 1: Verify the trainer owns this stream
  const livestream = await this.prisma.liveStream.findUnique({
    where: { id: livestreamId },
    select: {
      id: true,
      trainerId: true,
      status: true,
      scheduledAt: true,
      eventId: true,
    },
  });
  
  if (!livestream) {
    throw new HttpException(
      'Livestream not found',
      HttpStatus.NOT_FOUND,
    );
  }
  
  this.logger.log(`🔍 Checking authorization:`);
  this.logger.log(`   - Request from userId: ${trainerId} (type: ${typeof trainerId})`);
  this.logger.log(`   - Stream owner userId: ${livestream.trainerId} (type: ${typeof livestream.trainerId})`);
  this.logger.log(`   - Match: ${livestream.trainerId === trainerId}`);
  
  if (livestream.trainerId !== trainerId) {
    throw new HttpException(
      'Only the trainer can end this stream',
      HttpStatus.FORBIDDEN,
    );
  }
  
  // Step 2: Update livestream status to ENDED
  await this.prisma.liveStream.update({
    where: { id: livestreamId },
    data: { 
      status: LiveStreamStatus.ENDED,
    },
  });
  
  // ✅ Step 2.5: Finalize all participations (mark leftAt for anyone still in stream)
  const activeParticipations = await this.prisma.streamParticipation.findMany({
    where: {
      liveStreamId: livestreamId,
      leftAt: null,
    },
  });
  
  for (const participation of activeParticipations) {
    await this.prisma.streamParticipation.update({
      where: { id: participation.id },
      data: {
        leftAt: new Date(),
        pointsCredited: true,
      },
    });
    
    this.logger.log(`✅ Finalized participation for user ${participation.userId}`);
  }
  
  // Step 3: Update the linked Event status to COMPLETED
  if (livestream.eventId) {
    await this.prisma.event.update({
      where: { id: livestream.eventId },
      data: { 
        status: EventStatus.COMPLETED,
      },
    });
    
    this.logger.log(`Updated linked event ${livestream.eventId} to COMPLETED`);
  }
  
  
  this.logger.log(`Stream ${livestreamId} successfully ended`);


// Step 4: Emit event for any listeners
await this.redisEvents.emit('stream.ended', {
  streamId: livestreamId,
  trainerId: trainerId,
  endedAt: new Date(),
});

this.logger.log(`🔔 Stream ended event published to Redis`);  // ✅ ADD THIS


}




/**
 * Submit a review for a completed livestream
 */
async submitReview(
  livestreamId: string,
  userId: number,
  rating: number,
  feedback?: string,
): Promise<void> {
  this.logger.log(`User ${userId} submitting review for stream ${livestreamId}`);
  
  // Verify the stream exists and is completed
  const livestream = await this.prisma.liveStream.findUnique({
    where: { id: livestreamId },
    select: { status: true },
  });
  
  if (!livestream) {
    throw new HttpException('Livestream not found', HttpStatus.NOT_FOUND);
  }
  
  if (livestream.status !== LiveStreamStatus.ENDED) {
    throw new HttpException(
      'Can only review completed streams',
      HttpStatus.BAD_REQUEST,
    );
  }
  
  // Check if user actually participated in the stream
  const participation = await this.prisma.streamParticipation.findUnique({
    where: {
      userId_liveStreamId: {
        userId: userId,
        liveStreamId: livestreamId,
      },
    },
  });
  
  if (!participation) {
    throw new HttpException(
      'You must attend a stream to review it',
      HttpStatus.FORBIDDEN,
    );
  }
  
  // Create or update review
  await this.prisma.streamReview.upsert({
    where: {
      userId_livestreamId: {
        userId: userId,
        livestreamId: livestreamId,
      },
    },
    create: {
      userId: userId,
      livestreamId: livestreamId,
      rating: rating,
      feedback: feedback,
    },
    update: {
      rating: rating,
      feedback: feedback,
    },
  });
  
  this.logger.log(`✅ Review submitted: ${rating} stars`);
}


async muteParticipant(
  livestreamId: string,
  participantIdentity: string,
  muted: boolean,
  userId: number,
): Promise<{ success: boolean }> {
  console.log('🔇 === MUTE REQUEST ===');
  console.log('Livestream ID:', livestreamId);
  console.log('Participant Identity:', participantIdentity);
  console.log('Muted:', muted);
  
  const livestream = await this.prisma.liveStream.findUnique({
    where: { id: livestreamId },
  });

  if (!livestream) {
    throw new NotFoundException('Livestream not found');
  }

  if (livestream.trainerId !== userId) {
    throw new UnauthorizedException('Only the trainer can mute participants');
  }

  if (livestream.status !== LiveStreamStatus.LIVE) {
    throw new BadRequestException('Stream is not live');
  }

  try {
    const livekitHost = this.configService.get<string>('LIVEKIT_URL')!;
    const apiKey = this.configService.get<string>('LIVEKIT_API_KEY')!;
    const apiSecret = this.configService.get<string>('LIVEKIT_SECRET')!;

    const roomService = new RoomServiceClient(livekitHost, apiKey, apiSecret);
    
    // ✅ Get participant details to find their audio track SID
    const participants = await roomService.listParticipants(livestreamId);
    const targetParticipant = participants.find(p => p.identity === participantIdentity);
    
    if (!targetParticipant) {
      throw new NotFoundException('Participant not found in room');
    }
    
    console.log('👤 Found participant:', targetParticipant.name);
    console.log('📡 Their tracks:', targetParticipant.tracks);
    
    // Find the audio track
    const audioTrack = targetParticipant.tracks.find(t => t.name === 'microphone');
    
    if (!audioTrack) {
      throw new NotFoundException('Participant has no microphone track');
    }
    
    console.log('🎤 Found audio track SID:', audioTrack.sid);
    console.log('🚀 Muting track...');
    
    // ✅ Use the track SID instead of identity + source
    await roomService.mutePublishedTrack(
      livestreamId,
      participantIdentity,
      audioTrack.sid,  // ✅ Use track SID instead of 'microphone'
      muted,
    );

    console.log(`✅ ${muted ? 'Muted' : 'Unmuted'} track ${audioTrack.sid}`);

    return { success: true };
  } catch (error) {
    console.error('❌ Error muting participant:', error);
    console.error('Error details:', error.message);
    throw new InternalServerErrorException('Failed to mute participant');
  }
}



async removeParticipantFromRoom(livestreamId: string, participantSid: string): Promise<void> {
  this.logger.log(`🚫 Removing participant ${participantSid} from LiveKit room ${livestreamId}`);
  
  try {
    const livekitHost = this.configService.get<string>('LIVEKIT_URL')!;
    const apiKey = this.configService.get<string>('LIVEKIT_API_KEY')!;
    const apiSecret = this.configService.get<string>('LIVEKIT_SECRET')!;

    const roomService = new RoomServiceClient(livekitHost, apiKey, apiSecret);
    
    // ✅ ADD THIS: List all participants to debug
    const participants = await roomService.listParticipants(livestreamId);
    this.logger.log(`🔍 Participants in room: ${participants.map(p => `${p.identity} (${p.sid})`).join(', ')}`);
    this.logger.log(`🔍 Looking for SID: ${participantSid}`);
    
    //Remove participant from LiveKit room
    await roomService.removeParticipant(livestreamId, participantSid);
    
    this.logger.log(`✅ Participant ${participantSid} successfully removed from LiveKit room`);
  } catch (error) {
    this.logger.error(`❌ Failed to remove participant from LiveKit: ${error.message}`);
    throw new InternalServerErrorException('Failed to remove participant from room');
  }
}




/**
 * Get trainer's upcoming scheduled streams
 */
async getTrainerUpcomingStreams(trainerId: number): Promise<any[]> {
  this.logger.log(`🔍 Fetching upcoming streams for trainer ${trainerId}`);
  
  const streams = await this.prisma.liveStream.findMany({
    where: {
      trainerId: trainerId,
      status: LiveStreamStatus.SCHEDULED,
      scheduledAt: {
        gte: new Date(), // Only future streams
      },
    },
    include: {
      event: true,
    },
    orderBy: {
      scheduledAt: 'asc',
    },
    take: 30,
  });
  
  this.logger.log(`✅ Found ${streams.length} upcoming streams for trainer ${trainerId}`);
  
  // ✅ ADD THIS: Log the scheduled dates to see if they're in the future
  streams.forEach(stream => {
    this.logger.log(`   - Stream "${stream.title}" scheduled for ${stream.scheduledAt}`);
  });
  
  return streams;
}


}