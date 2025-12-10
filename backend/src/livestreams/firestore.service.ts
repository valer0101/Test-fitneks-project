import { Injectable } from '@nestjs/common';
import * as admin from 'firebase-admin';
import * as path from 'path';
import * as fs from 'fs';

@Injectable()
export class FirestoreService {
  private firestore: admin.firestore.Firestore | null = null;
  private isInitialized = false;

  constructor() {
    if (!admin.apps.length) {
      const serviceAccountPath = path.join(
        __dirname,
        '../../firebase-service-account.json',
      );

      if (fs.existsSync(serviceAccountPath)) {
        try {
          admin.initializeApp({
            credential: admin.credential.cert(serviceAccountPath),
            projectId: 'fitneks-live-gifts',
          });

          this.firestore = admin.firestore();
          this.isInitialized = true;
          console.log('✅ Firebase Admin initialized');
        } catch (error) {
          console.warn('⚠️  Firebase Admin initialization failed:', error.message);
          this.isInitialized = false;
        }
      } else {
        console.warn('⚠️  Firebase service account file not found. Firebase features will be disabled.');
        this.isInitialized = false;
      }
    } else {
      this.firestore = admin.firestore();
      this.isInitialized = true;
    }
  }

  async createLivestreamInvite(inviteData: {
    livestreamId: string;
    livestreamTitle: string;
    trainerId: string;
    trainerUsername: string;
    trainerDisplayName: string;
    senderId: string;
    senderUsername: string;
    senderDisplayName: string;
    recipientId: string;
    status: string;
    createdAt: Date;
    expiresAt: Date;
  }): Promise<void> {
    if (!this.isInitialized || !this.firestore) {
      console.warn('⚠️  Firebase not initialized. Skipping livestream invite creation.');
      return;
    }

    try {
      await this.firestore.collection('livestreamInvites').add({
        ...inviteData,
        createdAt: admin.firestore.Timestamp.fromDate(inviteData.createdAt),
        expiresAt: admin.firestore.Timestamp.fromDate(inviteData.expiresAt),
      });

      console.log(
        `✅ Livestream invite created: ${inviteData.senderId} invited ${inviteData.recipientId} to ${inviteData.livestreamId}`,
      );
    } catch (error) {
      console.error('❌ Error creating livestream invite:', error);
      throw error;
    }
  }

  async cleanupExpiredInvites(): Promise<number> {
    if (!this.isInitialized || !this.firestore) {
      console.warn('⚠️  Firebase not initialized. Skipping cleanup.');
      return 0;
    }

    try {
      const now = admin.firestore.Timestamp.now();

      const expiredInvites = await this.firestore
        .collection('livestreamInvites')
        .where('expiresAt', '<=', now)
        .where('status', '==', 'pending')
        .get();

      const deletePromises = expiredInvites.docs.map((doc) => doc.ref.delete());
      await Promise.all(deletePromises);

      console.log(`✅ Cleaned up ${expiredInvites.size} expired invites`);
      return expiredInvites.size;
    } catch (error) {
      console.error('❌ Error cleaning up expired invites:', error);
      throw error;
    }
  }
}