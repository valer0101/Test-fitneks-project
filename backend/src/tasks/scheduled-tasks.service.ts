import { Injectable } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { FirestoreService } from '../livestreams/firestore.service';

@Injectable()
export class ScheduledTasksService {
  constructor(private readonly firestoreService: FirestoreService) {}

  // Runs daily at midnight
  @Cron('0 0 * * *')
  async cleanupExpiredInvites() {
    console.log('🧹 Running daily cleanup of expired invites...');
    try {
      const count = await this.firestoreService.cleanupExpiredInvites();
      console.log(`✅ Cleaned up ${count} expired invites`);
    } catch (error) {
      console.error('❌ Error in cleanup job:', error);
    }
  }
}