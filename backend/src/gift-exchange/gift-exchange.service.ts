import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service'; // Adjust path as needed
import { GiftType, CurrencyType } from '@prisma/client';
import { ExchangeGiftDto } from './dto/exchange-gift.dto';
import { HistoryPeriod } from './dto/get-history.dto';

@Injectable()
export class GiftExchangeService {
  // Exchange rates as constants
  private readonly EXCHANGE_RATES = {
    PROTEIN: {
      TOKENS: 20,
      RUBIES: 3,
    },
    PROTEIN_SHAKE: {
      RUBIES: 9,
    },
    PROTEIN_BAR: {
      RUBIES: 15,
    },
  };

  constructor(private prisma: PrismaService) {}

  /**
   * Get user's current balances for currencies and gifts
   */
  async getBalances(userId: number) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        fitneksTokens: true,
        rubies: true,
        protein: true,
        proteinShakes: true,
        proteinBars: true,
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  /**
   * Exchange tokens or rubies for gifts
   * This is an atomic transaction
   */
  async exchangeGift(userId: number, dto: ExchangeGiftDto) {
    const { giftType, quantity, currencyUsed } = dto;

    // Validate currency is allowed for this gift type
    this.validateCurrencyForGiftType(giftType, currencyUsed);

    // Calculate total cost
    const totalCost = this.calculateCost(giftType, quantity, currencyUsed);

    // Perform atomic transaction
    return await this.prisma.$transaction(async (tx) => {
      // Fetch current user
      const user = await tx.user.findUnique({
        where: { id: userId },
      });

      if (!user) {
        throw new NotFoundException('User not found');
      }

      // Check if user has sufficient funds
      const currentBalance = currencyUsed === CurrencyType.TOKENS 
        ? user.fitneksTokens 
        : user.rubies;

      if (currentBalance < totalCost) {
        const currencyName = currencyUsed === CurrencyType.TOKENS ? 'tokens' : 'rubies';
        const needed = totalCost - currentBalance;
        throw new BadRequestException(
          `Insufficient funds. You need ${needed} more ${currencyName}.`
        );
      }

      // Prepare update data
      const updateData: any = {};

      // Decrement currency
      if (currencyUsed === CurrencyType.TOKENS) {
        updateData.fitneksTokens = user.fitneksTokens - totalCost;
      } else {
        updateData.rubies = user.rubies - totalCost;
      }

      // Increment gift inventory
      switch (giftType) {
        case GiftType.PROTEIN:
          updateData.protein = user.protein + quantity;
          break;
        case GiftType.PROTEIN_SHAKE:
          updateData.proteinShakes = user.proteinShakes + quantity;
          break;
        case GiftType.PROTEIN_BAR:
          updateData.proteinBars = user.proteinBars + quantity;
          break;
      }

      // Update user balances
      const updatedUser = await tx.user.update({
        where: { id: userId },
        data: updateData,
        select: {
          fitneksTokens: true,
          rubies: true,
          protein: true,
          proteinShakes: true,
          proteinBars: true,
        },
      });

      // Create purchase history record
      await tx.giftPurchase.create({
        data: {
          userId,
          giftType,
          quantity,
          currencyUsed,
          cost: totalCost,
        },
      });

      return updatedUser;
    });
  }

  /**
   * Get user's gift purchase history for a given period
   */
  async getHistory(userId: number, period: HistoryPeriod) {
    // Calculate the date range
    const now = new Date();
    const startDate = new Date();

    if (period === HistoryPeriod.WEEK) {
      startDate.setDate(now.getDate() - 7);
    } else {
      startDate.setDate(now.getDate() - 30);
    }

    // Fetch purchase history
    const purchases = await this.prisma.giftPurchase.findMany({
      where: {
        userId,
        createdAt: {
          gte: startDate,
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
      select: {
        id: true,
        createdAt: true,
        quantity: true,
        giftType: true,
      },
    });

    // Transform to match response format
    return purchases.map((purchase) => ({
      id: purchase.id,
      date: purchase.createdAt.toISOString(),
      quantity: purchase.quantity,
      giftName: this.getGiftDisplayName(purchase.giftType),
    }));
  }

  /**
   * Validate that the currency type is allowed for the gift type
   */
  private validateCurrencyForGiftType(
    giftType: GiftType,
    currencyUsed: CurrencyType,
  ) {
    // Only PROTEIN accepts both TOKENS and RUBIES
    if (giftType !== GiftType.PROTEIN && currencyUsed === CurrencyType.TOKENS) {
      throw new BadRequestException(
        `${giftType} can only be purchased with RUBIES`
      );
    }
  }

  /**
   * Calculate the total cost based on gift type, quantity, and currency
   */
  private calculateCost(
    giftType: GiftType,
    quantity: number,
    currencyUsed: CurrencyType,
  ): number {
    let ratePerUnit: number;

    switch (giftType) {
      case GiftType.PROTEIN:
        ratePerUnit = this.EXCHANGE_RATES.PROTEIN[currencyUsed];
        break;
      case GiftType.PROTEIN_SHAKE:
        ratePerUnit = this.EXCHANGE_RATES.PROTEIN_SHAKE.RUBIES;
        break;
      case GiftType.PROTEIN_BAR:
        ratePerUnit = this.EXCHANGE_RATES.PROTEIN_BAR.RUBIES;
        break;
      default:
        throw new BadRequestException('Invalid gift type');
    }

    return ratePerUnit * quantity;
  }

  /**
   * Get human-readable gift name for display
   */
  private getGiftDisplayName(giftType: GiftType): string {
    switch (giftType) {
      case GiftType.PROTEIN:
        return 'Proteins Purchased';
      case GiftType.PROTEIN_SHAKE:
        return 'Protein Shakes Purchased';
      case GiftType.PROTEIN_BAR:
        return 'Protein Bars Purchased';
      default:
        return 'Gift Purchased';
    }
  }
}