import { Strategy } from 'passport-local';
import { PassportStrategy } from '@nestjs/passport';
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { AuthService } from '../auth.service';

@Injectable()
export class LocalStrategy extends PassportStrategy(Strategy) {
  constructor(private authService: AuthService) {
    super({ usernameField: 'email' }); // Tell passport to use 'email' as the username
  }

  // This function is automatically called by the AuthGuard('local')
  async validate(email: string, pass: string): Promise<any> {
    const user = await this.authService.validateUser(email, pass); // You will need to create this method in AuthService
    if (!user) {
      throw new UnauthorizedException('Credentials incorrect');
    }
    return user;
  }
}