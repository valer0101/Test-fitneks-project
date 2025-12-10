// backend/src/auth/strategies/google.strategy.ts

import { PassportStrategy } from '@nestjs/passport';
import { Strategy, VerifyCallback } from 'passport-google-oauth20';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AuthService } from '../auth.service';

@Injectable()
export class GoogleStrategy extends PassportStrategy(Strategy, 'google') {
  constructor(
    private configService: ConfigService,
    private authService: AuthService,
  ) {
    const clientID = configService.get<string>('GOOGLE_CLIENT_ID') || 'dummy';
    const clientSecret = configService.get<string>('GOOGLE_CLIENT_SECRET') || 'dummy';
    const backendUrl = configService.get<string>('BACKEND_URL') || 'http://localhost:3000';
    
    if (clientID === 'dummy' || clientSecret === 'dummy') {
      console.warn('⚠️  Google OAuth credentials not configured. Google login will be disabled.');
    }
    
    super({
      clientID,
      clientSecret,
      callbackURL: `${backendUrl}/auth/google/callback`,
      scope: ['email', 'profile'],
      passReqToCallback: true,
    });
  }

  async validate(
    req: any,
    accessToken: string,
    refreshToken: string,
    profile: any,
    done: VerifyCallback,
  ): Promise<any> {
    const { name, emails, photos } = profile;
    const user = {
      email: emails[0].value,
      firstName: name.givenName,
      lastName: name.familyName,
      picture: photos[0].value,
      provider: 'google',
      providerId: profile.id,
    };

    const dbUser = await this.authService.validateOAuthUser(user);
    done(null, dbUser);
  }
}