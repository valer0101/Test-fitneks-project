import { ExtractJwt, Strategy } from 'passport-jwt';
import { PassportStrategy } from '@nestjs/passport';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from 'src/prisma/prisma.service';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(config: ConfigService, private prisma: PrismaService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: config.getOrThrow('JWT_SECRET'),
    });
  }

  // This function runs after the JWT is verified
  async validate(payload: { id: number; email: string }) {  // Changed 'sub' to 'id'
  const user = await this.prisma.user.findUnique({
    where: { id: payload.id },  // ✅ Now using payload.id
  });

  if (!user) {
    return null;
  }

  // It's safer to remove the password this way
  const { password, ...result } = user;
  return result;
}

}