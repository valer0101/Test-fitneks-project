import { Controller, Patch, Body, Get, UseGuards, Request, HttpStatus, HttpCode } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ProfileService } from './profile.service';
import { GetUser } from '../auth/decorator/get-user.decorator';
import { type User } from '@prisma/client';

@Controller('auth/profile')
@UseGuards(AuthGuard('jwt'))
export class ProfileController {
  constructor(private readonly profileService: ProfileService) {}

  @Get('balance')
  @HttpCode(HttpStatus.OK)
  async getUserBalance(@Request() req) {
    return this.profileService.getUserBalance(req.user.id);
  }

  @Get()
  @HttpCode(HttpStatus.OK)
  async getProfile(@Request() req) {
    return this.profileService.getProfile(req.user.id);
  }
}