import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class FriendsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Get all users who follow the specified user (their followers)
   */
  async getFollowers(userId: number) {
    const follows = await this.prisma.follows.findMany({
      where: { followingId: userId },
      include: {
        follower: {
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
    
    return follows.map(f => ({
      id: f.follower.id,
      username: f.follower.username,
      displayName: f.follower.displayName,
      imageUrl: f.follower.profilePictureUrl,
      points: f.follower.xp,
    }));
  }

  /**
   * Get all users that the specified user is following
   */
  async getFollowing(userId: number) {
    const follows = await this.prisma.follows.findMany({
      where: { followerId: userId },
      include: {
        following: {
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
    
    return follows.map(f => ({
      id: f.following.id,
      username: f.following.username,
      displayName: f.following.displayName,
      imageUrl: f.following.profilePictureUrl,
      points: f.following.xp,
    }));
  }

  /**
   * Remove a follower (block them from following you)
   */
  async removeFollower(currentUserId: number, followerToRemoveId: number) {
    const follow = await this.prisma.follows.findUnique({
      where: {
        followerId_followingId: {
          followerId: followerToRemoveId,
          followingId: currentUserId,
        },
      },
    });

    if (!follow) {
      throw new NotFoundException('Follow relationship not found');
    }

    await this.prisma.follows.delete({
      where: {
        followerId_followingId: {
          followerId: followerToRemoveId,
          followingId: currentUserId,
        },
      },
    });

    return { message: 'Follower removed successfully' };
  }

  /**
   * Unfollow a user (stop following them)
   */
  async unfollowUser(currentUserId: number, userToUnfollowId: number) {
    const follow = await this.prisma.follows.findUnique({
      where: {
        followerId_followingId: {
          followerId: currentUserId,
          followingId: userToUnfollowId,
        },
      },
    });

    if (!follow) {
      throw new NotFoundException('Follow relationship not found');
    }

    await this.prisma.follows.delete({
      where: {
        followerId_followingId: {
          followerId: currentUserId,
          followingId: userToUnfollowId,
        },
      },
    });

    return { message: 'User unfollowed successfully' };
  }
}