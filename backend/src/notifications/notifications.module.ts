import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bull';
import { NotificationsService, NotificationProcessor } from './notifications.service';
import { RedisEventsService } from './redis-events.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [
    PrismaModule,
    BullModule.registerQueue({ name: 'notifications' }),
  ],
  providers: [
    RedisEventsService,
    NotificationsService,
    NotificationProcessor,
  ],
  exports: [RedisEventsService],
})
export class NotificationsModule {}