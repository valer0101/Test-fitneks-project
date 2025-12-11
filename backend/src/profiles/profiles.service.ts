import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RedisEventsService } from '../notifications/redis-events.service';

@Injectable()
export class ProfilesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redisEvents: RedisEventsService,
  ) {}

  async getProfileByUsername(username: string, viewerId: number) {
    // Find the profile owner
    const profileOwner = await this.prisma.user.findUnique({
      where: { username },
      select: {
        id: true,
        displayName: true,
        username: true,
        role: true,
        isPublic: true,
        profilePictureUrl: true,
        liveStatus: true,
        aboutMe: true,
        xp: true,
        level: true,
        workoutTypes: true,
        goals: true,
        muscleGroups: true,
      },
    });

    if (!profileOwner) {
      throw new NotFoundException('User not found');
    }

    // Check follow relationships
    const viewerFollowsProfile = await this.prisma.follows.findUnique({
      where: {
        followerId_followingId: {
          followerId: viewerId,
          followingId: profileOwner.id,
        },
      },
    });

    const profileFollowsViewer = await this.prisma.follows.findUnique({
      where: {
        followerId_followingId: {
          followerId: profileOwner.id,
          followingId: viewerId,
        },
      },
    });

    // Get lifetime stats (placeholder - you'll need actual session/challenge data)
    const lifetimeSessions = 0; // TODO: Count from sessions table
    const lifetimeChallenges = 0; // TODO: Count from challenges table

    // Build unified response
    const baseProfile = {
      id: profileOwner.id,
      displayName: profileOwner.displayName,
      username: profileOwner.username,
      userType: profileOwner.role,
      isPublic: profileOwner.isPublic,
      profilePictureUrl: profileOwner.profilePictureUrl,
      liveStatus: profileOwner.liveStatus,
      aboutMe: profileOwner.aboutMe,
      stats: {
        lifetimePoints: profileOwner.role === 'Learner' ? profileOwner.xp : null,
        lifetimeXP: profileOwner.role === 'Trainer' ? profileOwner.xp : null,
        trainerLevel: profileOwner.role === 'Trainer' ? profileOwner.level : null,
        lifetimeSessions,
        lifetimeChallenges,
      },
      viewerContext: {
        viewerIsFollowing: !!viewerFollowsProfile,
        profileIsFollowingViewer: !!profileFollowsViewer,
      },
    };

    // Add role-specific data
    if (profileOwner.role === 'Trainer') {
      return {
        ...baseProfile,
        specialties: profileOwner.workoutTypes,
        calendarEvents: [], // TODO: Fetch from calendar/sessions
        interests: null,
        goals: null,
        advancedMetrics: null,
      };
    } else {
      return {
        ...baseProfile,
        specialties: null,
        calendarEvents: null,
        interests: profileOwner.muscleGroups,
        goals: profileOwner.goals,
        advancedMetrics: {
          weeklyPointsGraph: {}, // TODO: Calculate from workout history
          heatmap: {}, // TODO: Calculate from workout history
        },
      };
    }
  }

  async followUser(viewerId: number, usernameToFollow: string) {
    const userToFollow = await this.prisma.user.findUnique({
      where: { username: usernameToFollow },
    });

    if (!userToFollow) {
      throw new NotFoundException('User not found');
    }

    // ✅ Prevent self-following
    if (viewerId === userToFollow.id) {
      throw new BadRequestException('Cannot follow yourself');
    }

    // Check if already following
    const existingFollow = await this.prisma.follows.findUnique({
      where: {
        followerId_followingId: {
          followerId: viewerId,
          followingId: userToFollow.id,
        },
      },
    });

    if (existingFollow) {
      return { message: 'Successfully followed user' };
    }

    // Create follow relationship
    await this.prisma.follows.create({
      data: {
        followerId: viewerId,
        followingId: userToFollow.id,
      },
    });

    // ✅ Get the follower's username
    const follower = await this.prisma.user.findUnique({
      where: { id: viewerId },
      select: { username: true },
    });

    // ✅ Emit notification event with CORRECT usernames (handle null case)
    if (follower) {
      await this.redisEvents.emit('user.followed', {
        followerId: viewerId.toString(),
        followedUserId: userToFollow.id.toString(),
        followerUsername: follower.username,
      });
      console.log(`✅ Follow event emitted: User ${viewerId} followed ${userToFollow.id}`);
    }

    return { message: 'Successfully followed user' };
  }

  async unfollowUser(viewerId: number, usernameToUnfollow: string) {
    const userToUnfollow = await this.prisma.user.findUnique({
      where: { username: usernameToUnfollow },
    });

    if (!userToUnfollow) {
      throw new NotFoundException('User not found');
    }

    // Check if follow exists
    const existingFollow = await this.prisma.follows.findUnique({
      where: {
        followerId_followingId: {
          followerId: viewerId,
          followingId: userToUnfollow.id,
        },
      },
    });

    if (!existingFollow) {
      return { message: 'Successfully unfollowed user' };
    }

    // Delete follow relationship
    await this.prisma.follows.delete({
      where: {
        followerId_followingId: {
          followerId: viewerId,
          followingId: userToUnfollow.id,
        },
      },
    });

    return { message: 'Successfully unfollowed user' };
  }




async removeFollower(viewerId: number, followerUsername: string) {
  // Find the follower user
  const followerUser = await this.prisma.user.findUnique({
    where: { username: followerUsername },
  });

  if (!followerUser) {
    throw new NotFoundException('User not found');
  }

  // Check if this follow relationship exists
  // The follower is following the viewer, so:
  // followerId = followerUser.id
  // followingId = viewerId
  const existingFollow = await this.prisma.follows.findUnique({
    where: {
      followerId_followingId: {
        followerId: followerUser.id,
        followingId: viewerId,
      },
    },
  });

  if (!existingFollow) {
    throw new NotFoundException('Follow relationship not found');
  }

  // Delete the follow relationship
  await this.prisma.follows.delete({
    where: {
      followerId_followingId: {
        followerId: followerUser.id,
        followingId: viewerId,
      },
    },
  });

  return { message: 'Successfully removed follower' };
}




}