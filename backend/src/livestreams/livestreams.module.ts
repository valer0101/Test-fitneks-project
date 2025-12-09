import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bull';  // ✅ ADD THIS
import { PrismaModule } from '../prisma/prisma.module';
import { ConfigModule } from '@nestjs/config';  // ✅ Add this import
import { LivestreamsController } from './livestreams.controller';
import { LivestreamsService } from './livestreams.service';
import { PrismaService } from '../prisma/prisma.service';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { NotificationsModule } from '../notifications/notifications.module';  // ✅ ADD THIS
import { FirestoreService } from './firestore.service';  // ✅ ADD THIS


@Module({
  imports: [
    PrismaModule,
    NotificationsModule,  // ✅ ADD THIS
    BullModule.registerQueue({ name: 'notifications' }),  // ✅ ADD THIS
  ],
  controllers: [LivestreamsController],
  providers: [LivestreamsService, FirestoreService,],
})
export class LivestreamsModule {}