import { 
  Body, 
  Controller, 
  HttpCode, 
  HttpStatus, 
  Post,
  Get,
  UseGuards,
  Req,
  Res,
  Patch,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AuthService } from './auth.service';
import { CreateUserDto, LoginUserDto } from './dto/auth.dto';
import { ForgotPasswordDto, ResetPasswordDto } from 'src/auth/dto/password-reset.dto';
import { UpdateTrainerProfileDto } from './dto/update-profile.dto';
import { GetUser } from './decorator/get-user.decorator';
import { type User } from '@prisma/client';
import { type Request, type Response } from 'express';
import { ConfigService } from '@nestjs/config';
import { UpdateLearnerProfileDto } from './dto/update-learner-profile.dto';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from 'src/prisma/prisma.service';
import { UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';


@Controller('auth')
export class AuthController {
  constructor(
    private authService: AuthService,
    private configService: ConfigService,
    // FIX: Inject Prisma and JWT services to build a sanitized token
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  // POST /auth/register
  @Post('register')
  async register(@Body() createUserDto: CreateUserDto) {
    const newUser = await this.authService.register(createUserDto);

    // Sanitize the new user object to ensure numeric fields are not null.
    const sanitizedUser = {
      ...newUser,
      xp: newUser.xp ?? 0,
      level: newUser.level ?? 0,
      rubies: newUser.rubies ?? 0,
      proteinShakes: newUser.proteinShakes ?? 0,
      proteinBars: newUser.proteinBars ?? 0,
      profileBoosts: newUser.profileBoosts ?? 0,
      notifyBoosts: newUser.notifyBoosts ?? 0,
    };

    return sanitizedUser;
  }

  // POST /auth/login
  // FIX: Re-implement login logic to ensure the JWT payload is sanitized.
  @HttpCode(HttpStatus.OK)
  @Post('login')
  async login(@Body() loginUserDto: LoginUserDto) {
    const { email, password } = loginUserDto;
    
    const user = await this.prisma.user.findUnique({ where: { email } });

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);

    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Sanitize the user object before creating the JWT payload
    const sanitizedUser = {
      ...user,
      xp: user.xp ?? 0,
      level: user.level ?? 0,
      rubies: user.rubies ?? 0,
      proteinShakes: user.proteinShakes ?? 0,
      proteinBars: user.proteinBars ?? 0,
      profileBoosts: user.profileBoosts ?? 0,
      notifyBoosts: user.notifyBoosts ?? 0,
    };

    // Remove password from the object that will become the JWT payload
    const { password: _, ...payload } = sanitizedUser;

    // Sign the new, clean payload
    const accessToken = await this.jwtService.signAsync(payload);

    return { access_token: accessToken };
  }

  // Google OAuth endpoints
  @Get('google')
  @UseGuards(AuthGuard('google'))
  async googleAuth() {
    // Guard redirects to Google
  }  

  @Get('google/callback')
  @UseGuards(AuthGuard('google'))
  async googleAuthCallback(@Req() req: any, @Res() res: Response) {
    const jwt = await this.authService.generateJwtForOAuthUser(req.user);
    // Redirect to frontend with token
    res.redirect(`${process.env.FRONTEND_URL}/auth/callback?token=${jwt.access_token}`);
  }

  // Facebook OAuth endpoints
  @Get('facebook')
  @UseGuards(AuthGuard('facebook'))
  async facebookAuth() {
    // Guard redirects to Facebook
  }

  @Get('facebook/callback')
  @UseGuards(AuthGuard('facebook'))
  async facebookAuthCallback(@Req() req: any, @Res() res: Response) {
    const jwt = await this.authService.generateJwtForOAuthUser(req.user);
    // Redirect to frontend with token
    res.redirect(`${process.env.FRONTEND_URL}/auth/callback?token=${jwt.access_token}`);
  }

  // Password reset endpoints
  @Post('forgot-password')
  async forgotPassword(@Body() forgotPasswordDto: ForgotPasswordDto) {
    return this.authService.forgotPassword(forgotPasswordDto.email);
  }

  @Post('reset-password')
  async resetPassword(@Body() resetPasswordDto: ResetPasswordDto) {
    return this.authService.resetPassword(
      resetPasswordDto.token,
      resetPasswordDto.newPassword,
    );
  }

  // Update Trainer Profile  
  @Patch('profile')
  @UseGuards(AuthGuard('jwt'))
  updateProfile(
    @GetUser() user: User,
    @Body() dto: UpdateTrainerProfileDto,
  ) {
    return this.authService.updateProfile(user.id, dto);
  }

  // Update Learner Profile - UPDATED to return JWT token
  @Patch('profile/learner')
  @UseGuards(AuthGuard('jwt'))
  async updateLearnerProfile(
    @GetUser() user: User,
    @Body() dto: UpdateLearnerProfileDto,
  ) {
    const updatedUser = await this.authService.updateLearnerProfile(user.id, dto);

    // Sanitize numeric fields
    const sanitizedUser = {
      ...updatedUser,
      xp: updatedUser.xp ?? 0,
      level: updatedUser.level ?? 0,
      rubies: updatedUser.rubies ?? 0,
      proteinShakes: updatedUser.proteinShakes ?? 0,
      proteinBars: updatedUser.proteinBars ?? 0,
      profileBoosts: updatedUser.profileBoosts ?? 0,
      notifyBoosts: updatedUser.notifyBoosts ?? 0,
    };

    // Sign JWT (service already removes password)
    const accessToken = await this.jwtService.signAsync(sanitizedUser);

    return { access_token: accessToken };
  }

  // Profile Dashboard (My Profile Page)
  @Get('profile/me') 
  @UseGuards(AuthGuard('jwt'))
  getProfile(@GetUser() user: User) {
    // The @GetUser() decorator extracts the user from the validated JWT.
    
    // Remove the password before sending the user object back.
    const { password, ...result } = user;

    const sanitizedResult = {
      ...result,
      xp: result.xp ?? 0,
      level: result.level ?? 0,
      rubies: result.rubies ?? 0,
      proteinShakes: result.proteinShakes ?? 0,
      proteinBars: result.proteinBars ?? 0,
      profileBoosts: result.profileBoosts ?? 0,
      notifyBoosts: result.notifyBoosts ?? 0,
    };

    return sanitizedResult;
  }

// Add this right before the final closing brace of AuthController class

@Get('profile/learner/stats')
@UseGuards(AuthGuard('jwt'))
async getLearnerStats(@GetUser() user: User) {
  // Calculate total points from all muscle groups
  const totalPoints = 
    (user.armsPoints || 0) + 
    (user.chestPoints || 0) + 
    (user.backPoints || 0) + 
    (user.absPoints || 0) + 
    (user.legsPoints || 0) + 
    (user.challengePoints || 0);

  return {
    totalPoints: totalPoints * 100, // Flutter expects points * 100
    rubies: user.rubies || 0,
    weeklyGoal: user.weeklyGoal || 50,
    muscleGroupPoints: {
      arms: user.armsPoints || 0,
      chest: user.chestPoints || 0,
      back: user.backPoints || 0,
      abs: user.absPoints || 0,
      legs: user.legsPoints || 0,
      chlng: user.challengePoints || 0,
    },
    // Empty arrays until streaming is built
    completedSessions: [],
    completedChallenges: [],
    // Mock chart data - replace with real data later
    chartData: {
      arms: [3.5, 4.2, 5.0, 3.8],
      chest: [2.8, 3.5, 4.0, 3.2],
      back: [2.5, 3.0, 3.5, 2.8],
      abs: [2.0, 2.5, 3.0, 2.2],
      legs: [3.0, 3.5, 4.0, 3.2],
    },
  };
}





}