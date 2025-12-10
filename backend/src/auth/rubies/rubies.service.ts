import { Injectable, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class RubiesService {
  private readonly logger = new Logger(RubiesService.name);

  constructor(private readonly prisma: PrismaService) {}

  async transferRubies(senderId: number, livestreamId: string, amount: number) {
    // Step 1: Get the livestream and trainer info
    const livestream = await this.prisma.liveStream.findUnique({
      where: { id: livestreamId },
      include: { trainer: true },
    });

    if (!livestream) {
      throw new HttpException('Livestream not found', HttpStatus.NOT_FOUND);
    }

    // Step 2: Get sender's ruby balance
    const sender = await this.prisma.user.findUnique({
      where: { id: senderId },
    });

    if (!sender) {
      throw new HttpException('User not found', HttpStatus.NOT_FOUND);
    }

    if (sender.rubies < amount) {
      throw new HttpException('Insufficient ruby balance', HttpStatus.BAD_REQUEST);
    }

    // Step 3: Perform the transfer in a transaction
    const result = await this.prisma.$transaction(async (tx) => {
      // Deduct rubies from sender
      await tx.user.update({
        where: { id: senderId },
        data: { rubies: { decrement: amount } },
      });

      // Add rubies to trainer
      await tx.user.update({
        where: { id: livestream.trainerId },
        data: { rubies: { increment: amount } },
      });

      // Create transfer record (optional - for tracking)
      const transfer = await tx.rubyTransfer.create({
        data: {
          senderId: senderId,
          receiverId: livestream.trainerId,
          livestreamId: livestreamId,
          amount: amount,
        },
      });

      return transfer;
    });

    this.logger.log(`Ruby transfer completed: ${amount} rubies from user ${senderId} to trainer ${livestream.trainerId}`);

    return {
      success: true,
      transfer: result,
      message: `Transferred ${amount} rubies to ${livestream.trainer.displayName || livestream.trainer.username}`,
    };
  }
}