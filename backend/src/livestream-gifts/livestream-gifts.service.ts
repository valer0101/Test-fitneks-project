import { Injectable, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { GiftType } from '@prisma/client';

@Injectable()
export class LivestreamGiftsService {
  private readonly logger = new Logger(LivestreamGiftsService.name);

  constructor(private readonly prisma: PrismaService) {}

  async sendGift(
    senderId: number,
    livestreamId: string,
    giftType: string,
    cost: number,
    quantity?: number,
  ) {
    // ✅ Gift type validation INCLUDING Ruby
    const giftTypeMap: Record<string, { enum: GiftType; unitCost: number }> = {
      'RUBY': { enum: 'RUBY' as GiftType, unitCost: 1 },           // ✅ Added Ruby
      'PROTEIN': { enum: 'PROTEIN' as GiftType, unitCost: 3 },
      'PROTEIN_SHAKE': { enum: 'PROTEIN_SHAKE' as GiftType, unitCost: 9 },
      'PROTEIN_BAR': { enum: 'PROTEIN_BAR' as GiftType, unitCost: 15 },
    };

    const normalizedGiftType = giftType.toUpperCase();
    
    if (!giftTypeMap[normalizedGiftType]) {
      throw new HttpException(
        `Invalid gift type: ${giftType}. Must be one of: RUBY, PROTEIN, PROTEIN_SHAKE, PROTEIN_BAR`,  // ✅ Updated message
        HttpStatus.BAD_REQUEST,
      );
    }

    const giftConfig = giftTypeMap[normalizedGiftType];
    const giftTypeEnum = giftConfig.enum;
    const actualQuantity = quantity || 1;

    // ✅ CRITICAL: Validate cost matches gift type
    const expectedCost = giftConfig.unitCost * actualQuantity;
    if (cost !== expectedCost) {
      this.logger.error(
        `Cost validation failed for ${giftTypeEnum}: Expected ${expectedCost} (${giftConfig.unitCost} × ${actualQuantity}), got ${cost}`
      );
      // Use the CORRECT cost, not what was sent
      cost = expectedCost;
    }

    this.logger.log(
      `Processing ${giftTypeEnum === 'RUBY' ? 'ruby tip' : 'gift'}: ${giftTypeEnum} (quantity: ${actualQuantity}, cost: ${cost}) from user ${senderId}`  // ✅ Better logging
    );

    // Get sender's balance
    const sender = await this.prisma.user.findUnique({
      where: { id: senderId },
      select: {
        rubies: true,
        username: true,
        displayName: true,
      },
    });

    if (!sender) {
      throw new HttpException('User not found', HttpStatus.NOT_FOUND);
    }

    if (sender.rubies < cost) {
      throw new HttpException(
        `Insufficient ruby balance. You have ${sender.rubies} rubies but need ${cost}`,
        HttpStatus.BAD_REQUEST,
      );
    }

    // Verify livestream exists
    const livestream = await this.prisma.liveStream.findUnique({
      where: { id: livestreamId },
      include: {
        trainer: {
          select: {
            id: true,
            username: true,
            displayName: true,
          },
        },
      },
    });

    if (!livestream) {
      throw new HttpException('Livestream not found', HttpStatus.NOT_FOUND);
    }

    // ✅ Serializable transaction prevents race conditions
    try {
      const result = await this.prisma.$transaction(
        async (tx) => {
          // 1. Deduct rubies from sender (ALL gifts cost rubies)
          const updatedSender = await tx.user.update({
            where: { id: senderId },
            data: { rubies: { decrement: cost } },
            select: { rubies: true },
          });

          this.logger.log(
            `Deducted ${cost} rubies from user ${senderId}. New balance: ${updatedSender.rubies}`
          );

          // 2. ✅ NEW: If Ruby tip, ALSO credit trainer with rubies
          if (giftTypeEnum === 'RUBY') {
            await tx.user.update({
              where: { id: livestream.trainerId },
              data: { rubies: { increment: cost } },
            });

            this.logger.log(
              `Credited ${cost} rubies to trainer ${livestream.trainerId}`
            );

            // ✅ NEW: Create RubyTransfer record for accounting
            await tx.rubyTransfer.create({
              data: {
                senderId: senderId,
                receiverId: livestream.trainerId,
                livestreamId: livestreamId,
                amount: cost,
              },
            });

            this.logger.log(
              `Created RubyTransfer record for ${cost} rubies`
            );
          }

          // 3. Create gift record with VALIDATED cost (for ALL gift types)
          const gift = await tx.livestreamGift.create({
            data: {
              senderId: senderId,
              livestreamId: livestreamId,
              giftType: giftTypeEnum,
              quantity: actualQuantity,
            },
            include: {
              sender: {
                select: {
                  id: true,
                  username: true,
                  displayName: true,
                },
              },
            },
          });

          this.logger.log(
            `Created gift record: ${gift.id} - Type: ${gift.giftType}, Quantity: ${gift.quantity}`
          );

          return { gift, updatedBalance: updatedSender.rubies };
        },
        {
          isolationLevel: 'Serializable', // Prevents double-sends
          timeout: 10000,
        }
      );

      const giftTypeName = giftTypeEnum === 'RUBY'   // ✅ Better message formatting
        ? (actualQuantity === 1 ? 'ruby' : 'rubies')
        : giftTypeEnum.toLowerCase().replace('_', ' ');

      return {
        success: true,
        gift: {
          id: result.gift.id,
          giftType: result.gift.giftType,
          quantity: result.gift.quantity,
          sender: result.gift.sender,
          createdAt: result.gift.createdAt,
        },
        newBalance: result.updatedBalance,  // ✅ Return updated balance
        message: `Sent ${actualQuantity} ${giftTypeName} to ${
          livestream.trainer.displayName || livestream.trainer.username
        }`,
      };
    } catch (error) {
      this.logger.error(`Transaction failed: ${error.message}`, error.stack);
      
      if (error.code === 'P2034') {
        throw new HttpException(
          'Transaction conflict. Please try again.',
          HttpStatus.CONFLICT
        );
      }
      
      throw new HttpException(
        'Failed to send gift. Please try again.',
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }

  /**
   * Get gifts sent to a specific livestream (for trainer dashboard)
   */
  async getLivestreamGifts(livestreamId: string) {
    const gifts = await this.prisma.livestreamGift.findMany({
      where: { livestreamId },
      include: {
        sender: {
          select: {
            username: true,
            displayName: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    // Group gifts by type for summary
    const summary = gifts.reduce((acc, gift) => {
      acc[gift.giftType] = (acc[gift.giftType] || 0) + gift.quantity;
      return acc;
    }, {} as Record<string, number>);

    return {
      gifts,
      summary,
      total: gifts.length,
    };
  }

  /**
   * Get gifts sent by a specific user (for user dashboard)
   */
  async getUserSentGifts(userId: number) {
    return this.prisma.livestreamGift.findMany({
      where: { senderId: userId },
      include: {
        livestream: {
          select: {
            title: true,
            trainer: {
              select: {
                username: true,
                displayName: true,
              },
            },
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
  }
}