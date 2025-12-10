import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ProfilesService } from './profiles.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('api/profiles')
export class ProfilesController {
  constructor(private readonly profilesService: ProfilesService) {}

  @Get(':username')
  async getProfile(@Param('username') username: string, @Req() req) {
    return this.profilesService.getProfileByUsername(username, req.user.id);
  }

 @Post(':username/follow')
  async followUser(@Param('username') username: string, @Req() req) {
  console.log('🔍 [Follow Request] Authenticated user ID:', req.user.id);
  console.log('🔍 [Follow Request] Username to follow:', username);
  return this.profilesService.followUser(req.user.id, username);
}

  @Delete(':username/follow')
  async unfollowUser(@Param('username') username: string, @Req() req) {
    return this.profilesService.unfollowUser(req.user.id, username);
  }



  @Delete(':username/follower')
async removeFollower(@Param('username') username: string, @Req() req) {
  return this.profilesService.removeFollower(req.user.id, username);
}



}