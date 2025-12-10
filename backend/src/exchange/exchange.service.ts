import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { StripeService } from '../stripe/stripe.service';
import { WithdrawDto } from './dto/withdraw.dto';
import { PurchaseBoostDto } from './dto/purchase-boost.dto';
import { PurchaseRubiesDto } from './dto/purchase-rubies.dto';

@Injectable()
export class ExchangeService {
  constructor(
    private prisma: PrismaService,
    private stripeService: StripeService,
  ) {}

  // Get user's current inventory
  async getInventory(userId: number) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        rubies: true,
        proteinShakes: true,
        proteinBars: true,
        profileBoosts: true,
        notifyBoosts: true,
      },
    });

    if (!user) {
      throw new BadRequestException('User not found');
    }

    return {
      rubies: user.rubies || 0,
      proteinShakes: user.proteinShakes || 0,
      proteinBars: user.proteinBars || 0,
      profileBoosts: user.profileBoosts || 0,
      notifyBoosts: user.notifyBoosts || 0,
    };
  }

  // Withdraw money via Stripe
  async withdraw(userId: number, dto: WithdrawDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        proteinShakes: true,
        proteinBars: true,
        stripeAccountId: true, // You'll need this field for Stripe payouts
      },
    });

    if (!user) {
      throw new BadRequestException('User not found');
    }

    // Check if user has connected Stripe account for payouts
    if (!user.stripeAccountId) {
      throw new BadRequestException(
        'Please connect your bank account in settings to receive payments'
      );
    }

    // Validate inventory
    if (user.proteinShakes < dto.shakesToCashOut) {
      throw new BadRequestException('Insufficient protein shakes');
    }

    if (user.proteinBars < dto.barsToCashOut) {
      throw new BadRequestException('Insufficient protein bars');
    }

    // Calculate withdrawal amount
    const amountUSD = (dto.shakesToCashOut * 3) + (dto.barsToCashOut * 5);

    if (amountUSD === 0) {
      throw new BadRequestException('You do not have any gifts to withdraw');
    }

    // Check 24-hour withdrawal limit ($200 max per day)
    const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const recentWithdrawals = await this.prisma.withdrawalRequest.aggregate({
      where: {
        userId,
        createdAt: { gte: twentyFourHoursAgo },
      },
      _sum: {
        amountUSD: true,
      },
    });

    const totalLast24Hours = (recentWithdrawals._sum.amountUSD || 0) + amountUSD;
    if (totalLast24Hours > 200) {
      throw new BadRequestException(
        `Exceeds daily withdrawal limit. You can withdraw max $${200 - (recentWithdrawals._sum.amountUSD || 0)} today`
      );
    }

    // Process Stripe payout
    const payout = await this.stripeService.createPayout({
      amount: amountUSD * 100, // Convert to cents
      stripeAccountId: user.stripeAccountId,
    });

    // Create withdrawal request and update inventory
    const [withdrawalRequest] = await this.prisma.$transaction([
      this.prisma.withdrawalRequest.create({
        data: {
          userId,
          amountUSD,
          proteinShakesUsed: dto.shakesToCashOut,
          proteinBarsUsed: dto.barsToCashOut,
          status: 'COMPLETED',
          stripePayoutId: payout.id,
        },
      }),
      this.prisma.user.update({
        where: { id: userId },
        data: {
          proteinShakes: { decrement: dto.shakesToCashOut },
          proteinBars: { decrement: dto.barsToCashOut },
        },
      }),
    ]);

    return {
      success: true,
      message: 'Withdrawal successful',
      withdrawalId: withdrawalRequest.id,
      amountUSD,
    };
  }

  // Purchase boosts with rubies or protein
  async purchaseBoost(userId: number, dto: PurchaseBoostDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new BadRequestException('User not found');
    }

    let cost = { rubies: 0, protein: 0 };
    let boostField: string;

    // Calculate cost based on boost type
    if (dto.boostType === 'PROFILE') {
      boostField = 'profileBoosts';
      if (dto.currency === 'RUBIES') {
        cost.rubies = 9 * dto.quantity;
      } else {
        cost.protein = 3 * dto.quantity;
      }
    } else if (dto.boostType === 'NOTIFY') {
      boostField = 'notifyBoosts';
      if (dto.currency === 'RUBIES') {
        cost.rubies = 15 * dto.quantity;
      } else {
        cost.protein = 5 * dto.quantity;
      }
    } else {
      throw new BadRequestException('Invalid boost type');
    }

    // Validate sufficient funds
    if (dto.currency === 'RUBIES' && user.rubies < cost.rubies) {
      throw new BadRequestException('Insufficient rubies');
    }

    const totalProtein = user.proteinShakes + user.proteinBars;
    if (dto.currency === 'PROTEIN' && totalProtein < cost.protein) {
      throw new BadRequestException('Insufficient protein');
    }

    // Deduct protein (prioritize shakes, then bars)
    let shakesToDeduct = 0;
    let barsToDeduct = 0;

    if (cost.protein > 0) {
      shakesToDeduct = Math.min(cost.protein, user.proteinShakes);
      barsToDeduct = cost.protein - shakesToDeduct;
    }

    // Update user inventory
    const updateData: any = {
      [boostField]: { increment: dto.quantity },
    };

    if (cost.rubies > 0) {
      updateData.rubies = { decrement: cost.rubies };
    }

    if (shakesToDeduct > 0) {
      updateData.proteinShakes = { decrement: shakesToDeduct };
    }

    if (barsToDeduct > 0) {
      updateData.proteinBars = { decrement: barsToDeduct };
    }

    const updatedUser = await this.prisma.user.update({
      where: { id: userId },
      data: updateData,
      select: {
        rubies: true,
        proteinShakes: true,
        proteinBars: true,
        profileBoosts: true,
        notifyBoosts: true,
      },
    });

    return {
      success: true,
      message: `Successfully purchased ${dto.quantity} ${dto.boostType.toLowerCase()} boost(s)`,
      inventory: updatedUser,
    };
  }

  // Purchase rubies with Stripe
  async purchaseRubies(userId: number, dto: PurchaseRubiesDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new BadRequestException('User not found');
    }

    // Package pricing (updated to match frontend)
const packages = {
  'package_3': { rubies: 3, price: 199 },     // $1.99
  'package_9': { rubies: 9, price: 499 },     // $4.99
  'package_15': { rubies: 15, price: 699 },   // $6.99
  'package_30': { rubies: 30, price: 1299 },  // $12.99
  'package_60': { rubies: 60, price: 2499 },  // $24.99
  'package_120': { rubies: 120, price: 4899 }, // $48.99
  'package_240': { rubies: 240, price: 9699 }, // $96.99
  'package_480': { rubies: 480, price: 19299 }, // $192.99
};

    const selectedPackage = packages[dto.packageId];
    if (!selectedPackage) {
      throw new BadRequestException('Invalid package');
    }

    // Create Stripe payment intent
    const paymentIntent = await this.stripeService.createPaymentIntent({
      amount: selectedPackage.price,
      currency: 'usd',
      metadata: {
        userId: userId.toString(),
        packageId: dto.packageId,
        rubies: selectedPackage.rubies.toString(),
        type: 'ruby_purchase',
      },
    });

    return {
      clientSecret: paymentIntent.client_secret,
      packageId: dto.packageId,
      rubies: selectedPackage.rubies,
      amount: selectedPackage.price,
    };
  }

  // Called by Stripe webhook after successful payment
// In exchange.service.ts
async confirmRubyPurchase(userId: number, rubies: number) {
  await this.prisma.user.update({
    where: { id: userId },
    data: {
      rubies: {
        increment: rubies,
      },
    },
  });
  
  console.log(`✅ Added ${rubies} rubies to user ${userId}`);
}
}