import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Profile, Strategy } from 'passport-facebook';
import { ConfigService } from '@nestjs/config';
import { AuthService } from '../auth.service';

@Injectable()
export class FacebookStrategy extends PassportStrategy(Strategy, 'facebook') {
  constructor(
    private configService: ConfigService,
    private authService: AuthService,
  ) {
    super({
      clientID: configService.getOrThrow('FACEBOOK_APP_ID'),
      clientSecret: configService.getOrThrow('FACEBOOK_APP_SECRET'),
      callbackURL: `${configService.getOrThrow('BACKEND_URL')}/auth/facebook/callback`,
      scope: 'email',
      profileFields: ['id', 'emails', 'name'],
    });
  }

  async validate(
    accessToken: string,
    refreshToken: string,
    profile: Profile,
    done: (err: any, user: any, info?: any) => void,
  ): Promise<any> {
    // Extract the necessary info from the user's Facebook profile
    const { id, emails } = profile;

    if (!emails || emails.length === 0) {
  return done(new Error('No email found in Facebook profile'), null);
}

    const userPayload = {
      provider: 'facebook',
      providerId: id,
      email: emails[0].value, // Use the primary email from Facebook
    };

    // Find or create the user in your database using the logic in AuthService
    const user = await this.authService.validateOAuthUser(userPayload);
    
    // Passport.js expects the 'done' callback to be called with the user
    done(null, user);
  }
}