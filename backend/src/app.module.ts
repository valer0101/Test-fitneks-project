import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config'; 
import { BullModule } from '@nestjs/bull';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { ProfileModule } from './profile/profile.module'; 
import { PaymentModule } from './payment/payment.module';
import { FriendsModule } from './friends/friends.module';
import { ProfilesModule } from './profiles/profiles.module';
import { CalendarModule } from './calendar/calendar.module';
import { ExchangeModule } from './exchange/exchange.module';
import { LearnerPaymentModule } from './learner-payment/learner-payment.module';
import { GiftExchangeModule } from './gift-exchange/gift-exchange.module';
import { LivestreamsModule } from './livestreams/livestreams.module';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { LivestreamGiftsModule } from './livestream-gifts/livestream-gifts.module';
import { RubiesModule } from './auth/rubies/rubies.module';
import { NotificationsModule } from './notifications/notifications.module';
import { ScheduleModule } from '@nestjs/schedule';  // ✅ ADD THIS
import { ScheduledTasksService } from './tasks/scheduled-tasks.service';  // ✅ ADD THIS
import { FirestoreService } from './livestreams/firestore.service';  



@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    ScheduleModule.forRoot(),  // ✅ ADD THIS - enables cron jobs

    // ✅ NEW: Configure BullMQ with Redis
    BullModule.forRootAsync({
      useFactory: () => ({
        redis: {
          host: process.env.REDIS_HOST || 'localhost',
          port: parseInt(process.env.REDIS_PORT || '6379'),
        },
      }),
    }),
    // ✅ NEW: Register notification queue
    BullModule.registerQueue({
      name: 'notifications',
    }),
    EventEmitterModule.forRoot(),
    PrismaModule,
    AuthModule,
    ProfileModule,
    PaymentModule,
    FriendsModule,
    ProfilesModule,
    CalendarModule,
    ExchangeModule,
    LearnerPaymentModule,
    GiftExchangeModule,
    LivestreamsModule,
    LivestreamGiftsModule,
    RubiesModule,
    NotificationsModule,
  ],
  controllers: [AppController],
  providers: [AppService,
    ScheduledTasksService,
    FirestoreService,
  ],
})
export class AppModule {}