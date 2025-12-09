import {
  Controller,
  Post,
  Get,
  Patch,
  Body,
  Param,
  UseGuards,
  Request,
  BadRequestException,
  HttpStatus,
  NotFoundException,
  ForbiddenException,
  InternalServerErrorException,
  HttpException,
  Logger,
  Req,
  UnauthorizedException,
} from '@nestjs/common';
import type { User } from '@prisma/client';
import { LivestreamsService } from './livestreams.service';
import { CreateLivestreamDto } from './dto/create-livestream.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/decorator/roles.decorator';
import { GetUser } from '../auth/decorator/get-user.decorator';  // ✅ Add this
import { PrismaService } from '../prisma/prisma.service';
import { FirestoreService } from './firestore.service';  // ✅ Correct - same directory
import { RedisEventsService } from '../notifications/redis-events.service';  



@Controller('api/livestreams')
@UseGuards(JwtAuthGuard, RolesGuard)
export class LivestreamsController {
    
  private readonly logger = new Logger(LivestreamsController.name);

  constructor(
  private readonly livestreamsService: LivestreamsService,
  private readonly prisma: PrismaService,  // Add this if missing
  private readonly redisEventsService: RedisEventsService,
  private readonly firestoreService: FirestoreService,  // ✅ ADD THIS


) {}

  /**
   * Create a new livestream
   * Requires TRAINER role
   */
  @Post()
  @Roles('Trainer')
  async createLivestream(
    @Body() createLivestreamDto: CreateLivestreamDto,
    @GetUser() user: User,
  ) {
    try {
      const trainerId = user.id;
      
      this.logger.log(`Creating livestream for trainer: ${trainerId}`);
      
      const livestream = await this.livestreamsService.createLivestream(
        createLivestreamDto,
        trainerId,
      );
      
      return {
        status: HttpStatus.CREATED,
        message: 'Livestream created successfully',
        data: livestream,
      };
    } catch (error) {
      this.logger.error('Failed to create livestream', error.stack);
      
      if (error instanceof HttpException) {
        throw error;
      }
      
      throw new HttpException(
        'Failed to create livestream',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }


@Get('by-event/:eventId')
@UseGuards(JwtAuthGuard)
async getLivestreamByEventId(
  @Param('eventId') eventId: string,
  @Request() req,
) {
  // ✅ Add debugging
  this.logger.log(`📡 Getting livestream for event: ${eventId}`);
  this.logger.log(`👤 User ID from token: ${req.user?.userId}`);
  
  const livestream = await this.livestreamsService.getLivestreamByEventId(eventId);
  
  if (!livestream) {
    this.logger.warn(`❌ Livestream not found for event: ${eventId}`);
    throw new NotFoundException('Livestream not found for this event');
  }
  
  this.logger.log(`✅ Found livestream: ${livestream.id}, trainer: ${livestream.trainerId}`);
  
  // Check if user is the trainer
  if (livestream.trainerId !== req.user.id) {
    this.logger.warn(`🚫 User ${req.user.id} tried to edit livestream owned by ${livestream.trainerId}`);
    throw new ForbiddenException('You can only edit your own livestreams');
  }
  
  return { data: livestream };
}


/**
 * Get livestream by ID
 * Anyone authenticated can view
 */
@Get(':id')
@UseGuards(JwtAuthGuard)
async getLivestream(
  @Param('id') id: string,
  @Request() req,
) {
  this.logger.log(`📡 Getting livestream: ${id}`);
  this.logger.log(`👤 User ID from token: ${req.user?.id}`);
  
  const livestream = await this.livestreamsService.getLivestreamById(id);
  
  if (!livestream) {
    this.logger.warn(`❌ Livestream not found: ${id}`);
    throw new NotFoundException('Livestream not found');
  }
  
  this.logger.log(`✅ Found livestream: ${livestream.id}`);
  
  return {
    status: HttpStatus.OK,
    data: livestream,
  };
}




@Get('trainer/:trainerId/upcoming')
async getTrainerUpcomingStreams(@Param('trainerId') trainerId: string) {
  return this.livestreamsService.getTrainerUpcomingStreams(parseInt(trainerId));
}



/**
 * Join a livestream (for both trainers and learners)
 * Validates permissions and gift requirements
 */
@Post(':id/join')
@UseGuards(JwtAuthGuard)
async joinLivestream(
  @Param('id') id: string,
  @Request() req,
) {
  const userId = req.user.id;
  
  this.logger.log(`🔍 Checking ban for userId: ${userId}, livestreamId: ${id}`);
  
  // ✅ USE findFirst instead of findUnique
  const isBanned = await this.prisma.bannedStreamParticipant.findFirst({
    where: {
      livestreamId: id,
      userId: userId,
    },
  });

  if (isBanned) {
    this.logger.warn(`🚫 Banned user ${userId} attempted to join stream ${id}`);
    throw new ForbiddenException(
      'You have been removed from this livestream and cannot rejoin.',
    );
  }
  
  return this.livestreamsService.joinLivestream(id, userId);
}



/**
 * Grant video permission to a learner
 * Only callable by the trainer of the stream
 */
@Post(':id/grant-permission')
@UseGuards(JwtAuthGuard)
async grantVideoPermission(
  @Param('id') id: string,
  @Body() body: { learnerId: string },
  @Request() req,
) {
  return this.livestreamsService.grantVideoPermission(
    id,
    body.learnerId,
    req.user.id,
  );
}



@Patch(':id')
@UseGuards(JwtAuthGuard)
async updateLivestream(
  @Param('id') id: string,
  @Body() updateDto: CreateLivestreamDto,
  @Request() req,
) {
  this.logger.log(`📝 Updating livestream: ${id}`);
  this.logger.log(`👤 User ID: ${req.user.id}`);
  
  // Check if livestream exists and user owns it
  const livestream = await this.livestreamsService.getLivestream(id);
  
  if (!livestream) {
    this.logger.warn(`❌ Livestream not found: ${id}`);
    throw new NotFoundException('Livestream not found');
  }
  
  if (livestream.trainerId !== req.user.id) {
    this.logger.warn(`🚫 User ${req.user.id} tried to edit livestream owned by ${livestream.trainerId}`);
    throw new ForbiddenException('You can only edit your own livestreams');
  }
  
  this.logger.log(`✅ Updating livestream ${id}`);
  
  const updated = await this.livestreamsService.updateLivestream(id, updateDto);
  
  // Also update the linked event if it exists
  if (livestream.eventId) {
    try {
      await this.livestreamsService.updateLinkedEvent(livestream.eventId, updateDto);
      this.logger.log(`✅ Updated linked event: ${livestream.eventId}`);
    } catch (error) {
      this.logger.warn(`⚠️ Failed to update linked event: ${error.message}`);
    }
  }
  
  return { data: updated };
}




@Post(':id/approve-learner')
@UseGuards(JwtAuthGuard)
async approveLearner(
  @Param('id') livestreamId: string,
  @Body() body: { learnerId: string },
  @Request() req
) {
  try {
    const trainerId = req.user.id;
    const { learnerId } = body;

    // Use existing service method
    const livestream = await this.livestreamsService.getLivestream(livestreamId);

    if (!livestream || livestream.trainerId !== trainerId) {
      throw new ForbiddenException('Not authorized to approve learners for this stream');
    }

    // Get learner info directly via service's prisma
    const learner = await this.livestreamsService.getUserById(parseInt(learnerId));

    if (!learner) {
      throw new NotFoundException('Learner not found');
    }

    // Generate new LiveKit token with canPublish: true
   // Use existing service method to generate token with canPublish: true
const newToken = await this.livestreamsService.generateLiveKitToken(
  `learner_${learner.id}`,
  livestreamId,
  learner.displayName || learner.username,
  true  // isOwner = true gives canPublish permission
);

    return {
  token: newToken,
  message: 'Learner approved for video participation'
};

  } catch (error) {
    this.logger.error('Error approving learner:', error);
    throw new InternalServerErrorException('Failed to approve learner');
  }
}





// Award points to a learner during a livestream
@Post(':livestreamId/award-points')
@UseGuards(JwtAuthGuard)
async awardPoints(
  @Param('livestreamId') livestreamId: string,
  @Body() body: { learnerId: string; points: Record<string, number> },
  @Req() req: any,
) {
  const trainerId = req.user.id;
  
  // Verify the trainer owns this livestream
  const livestream = await this.prisma.liveStream.findFirst({
    where: {
      id: livestreamId,
      trainerId: trainerId,
    },
  });
  
  if (!livestream) {
    throw new UnauthorizedException('Not authorized to award points for this stream');
  }
  
  const learnerIdNum = parseInt(body.learnerId.replace('learner_', ''));
  
  // Update or create StreamParticipation
  const participation = await this.prisma.streamParticipation.upsert({
    where: {
      userId_liveStreamId: {
        userId: learnerIdNum,
        liveStreamId: livestreamId,
      },
    },
    update: {
      armsEarned: { increment: body.points.arms || 0 },
      chestEarned: { increment: body.points.chest || 0 },
      backEarned: { increment: body.points.back || 0 },
      absEarned: { increment: body.points.abs || 0 },
      legsEarned: { increment: body.points.legs || 0 },
      totalEarned: { 
        increment: Object.values(body.points).reduce((sum, val) => sum + val, 0) 
      },
    },
    create: {
      userId: learnerIdNum,
      liveStreamId: livestreamId,
      armsEarned: body.points.arms || 0,
      chestEarned: body.points.chest || 0,
      backEarned: body.points.back || 0,
      absEarned: body.points.abs || 0,
      legsEarned: body.points.legs || 0,
      totalEarned: Object.values(body.points).reduce((sum, val) => sum + val, 0),
    },
  });
  
  // Also update user's total points
  await this.prisma.user.update({
    where: { id: learnerIdNum },
    data: {
      armsPoints: { increment: body.points.arms || 0 },
      chestPoints: { increment: body.points.chest || 0 },
      backPoints: { increment: body.points.back || 0 },
      absPoints: { increment: body.points.abs || 0 },
      legsPoints: { increment: body.points.legs || 0 },
    },
  });
  
  return {
    success: true,
    participation,
  };
}



@Post(':id/end')
@UseGuards(JwtAuthGuard)
async endLivestream(
  @Param('id') id: string,
  @Req() req: any,
) {
  const userId = req.user.id;  // ✅ FIXED - now matches other endpoints
  await this.livestreamsService.endLivestream(id, userId);
  
  return {
    success: true,
    message: 'Livestream ended successfully',
  };
}




@Post(':id/review')
@UseGuards(JwtAuthGuard)
async submitReview(
  @Param('id') id: string,
  @Body() body: { rating: number; feedback?: string },
  @Req() req: any,
) {
  const userId = req.user.id;
  
  await this.livestreamsService.submitReview(
    id,
    userId,
    body.rating,
    body.feedback,
  );
  
  return {
    success: true,
    message: 'Review submitted successfully',
  };
}



@Post(':id/mute-participant')
@UseGuards(JwtAuthGuard)
async muteParticipant(
  @Param('id') id: string,
  @Body() muteDto: { participantIdentity: string; muted: boolean },
  @Request() req,
) {
  return this.livestreamsService.muteParticipant(
    id,
    muteDto.participantIdentity,
    muteDto.muted,
    req.user.id,
  );
}



@Post(':livestreamId/remove-participant')
@UseGuards(JwtAuthGuard)
async removeParticipant(
  @Param('livestreamId') livestreamId: string,
  @Body() body: { userId: string; participantSid: string },
  @Req() req: any,
) {
  const trainerId = req.user.id;
  const { userId, participantSid } = body;

  this.logger.log(`🚫 ===== REMOVE PARTICIPANT =====`);
  this.logger.log(`🚫 Livestream: ${livestreamId}`);
  this.logger.log(`🚫 User ID from request: ${userId} (type: ${typeof userId})`);
  this.logger.log(`🚫 Parsed User ID: ${parseInt(userId)} (type: ${typeof parseInt(userId)})`);
  this.logger.log(`🚫 Participant SID: ${participantSid}`);
  this.logger.log(`🚫 Banned By (Trainer): ${trainerId}`);

  if (!userId || !participantSid) {
    throw new HttpException('Missing userId or participantSid', HttpStatus.BAD_REQUEST);
  }

  const livestream = await this.prisma.liveStream.findUnique({
    where: { id: livestreamId },
    select: { trainerId: true, status: true },
  });

  if (!livestream) {
    throw new NotFoundException('Livestream not found');
  }

  if (livestream.trainerId !== trainerId) {
    throw new ForbiddenException('Only the trainer can remove participants');
  }

  if (livestream.status !== 'LIVE') {
    throw new HttpException(
      'Can only remove from live streams',
      HttpStatus.BAD_REQUEST,
    );
  }

  const userIdInt = parseInt(userId);

  // Check if already banned
  this.logger.log(`🔍 Checking for existing ban...`);
  const existingBan = await this.prisma.bannedStreamParticipant.findUnique({
    where: {
      livestreamId_userId: {
        livestreamId,
        userId: userIdInt,
      },
    },
  });

  if (existingBan) {
    this.logger.log(`⚠️ User ${userIdInt} is already banned`);
    this.logger.log(`⚠️ Existing ban: ${JSON.stringify(existingBan)}`);
  } else {
    // Create new ban record
    this.logger.log(`📝 Creating ban record...`);
    const banRecord = await this.prisma.bannedStreamParticipant.create({
      data: {
        livestreamId,
        userId: userIdInt,
        participantSid,
        bannedAt: new Date(),
        bannedBy: trainerId,
      },
    });
    this.logger.log(`✅ Ban record created: ${JSON.stringify(banRecord)}`);
  }

  // ALWAYS kick from LiveKit
  try {
    await this.livestreamsService.removeParticipantFromRoom(
      livestreamId,
      participantSid,
    );
    this.logger.log(`✅ User ${userIdInt} kicked from LiveKit room`);
  } catch (error) {
    this.logger.error(`❌ Failed to kick from LiveKit: ${error.message}`);
  }

  this.logger.log(`🚫 ===== END REMOVE PARTICIPANT =====`);

  return { 
    success: true, 
    message: 'User removed and banned from stream',
  };
}


@Post(':id/invite')
@UseGuards(JwtAuthGuard)
async inviteFriendsToLivestream(
  @Param('id') livestreamId: string,
  @Body() inviteDto: { recipientIds: number[] },
  @Request() req,
) {
  const senderId = req.user.userId;
  const { recipientIds } = inviteDto;

  if (!recipientIds || recipientIds.length === 0) {
    throw new BadRequestException('recipientIds cannot be empty');
  }

  if (recipientIds.length > 7) {
    throw new BadRequestException('Cannot invite more than 7 friends at once');
  }

  const livestream = await this.prisma.liveStream.findUnique({
    where: { id: livestreamId },
    include: {
      trainer: {
        select: {
          id: true,
          username: true,
          displayName: true,
        },
      },
    },
  });

  if (!livestream) {
    throw new NotFoundException('Livestream not found');
  }

  if (livestream.status !== 'LIVE') {
    throw new BadRequestException('Can only invite friends to live streams');
  }

  const sender = await this.prisma.user.findUnique({
    where: { id: senderId },
    select: {
      username: true,
      displayName: true,
    },
  });

  // ✅ FIXED: Handle null sender
  if (!sender) {
    throw new NotFoundException('Sender not found');
  }

  const invitePromises = recipientIds.map(async (recipientId) => {
    const isFollowing = await this.prisma.follows.findUnique({
      where: {
        followerId_followingId: {
          followerId: senderId,
          followingId: recipientId,
        },
      },
    });

    if (!isFollowing) {
      console.warn(`User ${recipientId} is not following ${senderId}, skipping invite`);
      return null;
    }

    const inviteData = {
      livestreamId,
      livestreamTitle: livestream.title,
      trainerId: livestream.trainerId.toString(),
      trainerUsername: livestream.trainer.username,
      trainerDisplayName: livestream.trainer.displayName,
      senderId: senderId.toString(),
      senderUsername: sender.username,
      senderDisplayName: sender.displayName,
      recipientId: recipientId.toString(),
      status: 'pending',
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
    };

    await this.firestoreService.createLivestreamInvite(inviteData);

    await this.redisEventsService.emit(`user:${recipientId}:notifications`, {
      type: 'LIVESTREAM_INVITE',
      livestreamId,
      livestreamTitle: livestream.title,
      senderUsername: sender.username,
      senderDisplayName: sender.displayName,
      trainerUsername: livestream.trainer.username,
      timestamp: new Date().toISOString(),
    });

    return recipientId;
  });

  const results = await Promise.all(invitePromises);
  const successfulInvites = results.filter((id) => id !== null);

  return {
    message: `Successfully invited ${successfulInvites.length} friend(s)`,
    invitedCount: successfulInvites.length,
    invitedUserIds: successfulInvites,
  };
}





@Post('event/:eventId/register')
@UseGuards(JwtAuthGuard)
async registerForEvent(
  @Param('eventId') eventId: string,
  @Request() req,
) {
  const userId = req.user.id;
  
  this.logger.log(`📅 User ${userId} registering for event ${eventId}`);
  
  // Find the event
  const event = await this.prisma.event.findUnique({
    where: { id: eventId },
  });
  
  if (!event) {
    throw new NotFoundException('Event not found');
  }
  
  if (event.status !== 'UPCOMING') {
    throw new BadRequestException('Can only register for upcoming events');
  }
  
  // Check if already registered
  const existing = await this.prisma.eventRegistration.findUnique({
    where: {
      userId_eventId: {
        userId,
        eventId,
      },
    },
  });
  
  if (existing) {
    return {
      success: true,
      message: 'Already registered for this event',
      registration: existing,
    };
  }
  
  // Create registration
  const registration = await this.prisma.eventRegistration.create({
    data: {
      userId,
      eventId,
      registeredAt: new Date(),
    },
  });
  
  this.logger.log(`✅ User ${userId} registered for event ${eventId}`);
  
  return {
    success: true,
    message: 'Successfully registered for event',
    registration,
  };
}





}