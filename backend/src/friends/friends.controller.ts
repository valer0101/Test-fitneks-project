import {
  Controller,
  Get,
  Delete,
  Param,
  Req,
  UseGuards,
  ParseIntPipe,
} from '@nestjs/common';
import { FriendsService } from './friends.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('api/friends')
export class FriendsController {
  constructor(private readonly friendsService: FriendsService) {}

  /**
   * GET /api/friends/followers
   * Returns list of users who follow the current user
   */
  @Get('followers')
  async getFollowers(@Req() req) {
    return this.friendsService.getFollowers(req.user.id);
  }

  /**
   * GET /api/friends/following
   * Returns list of users the current user is following
   */
  @Get('following')
  async getFollowing(@Req() req) {
    return this.friendsService.getFollowing(req.user.id);
  }

  /**
   * DELETE /api/friends/follower/:userId
   * Remove a follower (prevent them from following you)
   */
  @Delete('follower/:userId')
  async removeFollower(
    @Req() req,
    @Param('userId', ParseIntPipe) userId: number,
  ) {
    return this.friendsService.removeFollower(req.user.id, userId);
  }

  /**
   * DELETE /api/friends/unfollow/:userId
   * Unfollow a user
   */
  @Delete('unfollow/:userId')
  async unfollowUser(
    @Req() req,
    @Param('userId', ParseIntPipe) userId: number,
  ) {
    return this.friendsService.unfollowUser(req.user.id, userId);
  }
}