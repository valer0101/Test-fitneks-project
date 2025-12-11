import { Module } from '@nestjs/common';
import { LivestreamGiftsController } from './livestream-gifts.controller';
import { LivestreamGiftsService } from './livestream-gifts.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [LivestreamGiftsController],
  providers: [LivestreamGiftsService],
  exports: [LivestreamGiftsService],
})
export class LivestreamGiftsModule {}