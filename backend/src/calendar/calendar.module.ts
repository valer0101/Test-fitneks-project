import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bull';
import { CalendarService } from './calendar.service';
import { CalendarController } from './calendar.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { NotificationsModule } from '../notifications/notifications.module';  // ✅ CORRECT IMPORT

@Module({
  imports: [
    PrismaModule,
    NotificationsModule,  // ✅ Import the notifications module
    BullModule.registerQueue({
      name: 'notifications',
    }),
  ],
  controllers: [CalendarController],
  providers: [CalendarService],
  exports: [CalendarService],
})
export class CalendarModule {}