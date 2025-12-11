import { Injectable } from '@nestjs/common';
import * as admin from 'firebase-admin';
import * as path from 'path';

@Injectable()
export class FirestoreService {
  private firestore: admin.firestore.Firestore;

  constructor() {
    if (!admin.apps.length) {
      const serviceAccountPath = path.join(
        __dirname,
        '../../firebase-service-account.json',
      );

      admin.initializeApp({
        credential: admin.credential.cert(serviceAccountPath),
        projectId: 'fitneks-live-gifts',
      });

      console.log('✅ Firebase Admin initialized');
    }
    this.firestore = admin.firestore();
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