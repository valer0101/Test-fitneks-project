import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';
import { Payout, PayoutStatus } from '@prisma/client';

@Injectable()
export class PaymentService {
  private stripe: Stripe | null = null;
  private logger = new Logger(PaymentService.name);

  constructor(
    private prisma: PrismaService,
    private configService: ConfigService,
  ) {
    // Initialize Stripe with secret key from environment
    const stripeSecretKey = this.configService.get<string>('STRIPE_SECRET_KEY');
    
    if (!stripeSecretKey || stripeSecretKey.trim() === '') {
      this.logger.warn('⚠️  STRIPE_SECRET_KEY is not configured. Stripe features will be disabled.');
      this.stripe = null;
    } else {
      this.stripe = new Stripe(stripeSecretKey, {
        apiVersion: '2025-09-30.clover',
      });
    }
  }

  /**
   * Creates a Stripe Connect Express account and generates onboarding link
   * @param userId - ID of the user to onboard
   * @returns Stripe onboarding URL
   */
  async createStripeOnboardingLink(userId: number): Promise<string> {
    if (!this.stripe) {
      throw new Error('Stripe is not configured. Please set STRIPE_SECRET_KEY in environment variables.');
    }

    try {
      // Fetch user from database
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
      });

      if (!user) {
        throw new Error('User not found');
      }

      let stripeAccountId = user.stripeAccountId;

      // Create new Stripe Express account if user doesn't have one
      if (!stripeAccountId) {
        const account = await this.stripe.accounts.create({
          type: 'express',
          email: user.email,
          capabilities: {
            transfers: { requested: true },
          },
          metadata: {
            userId: userId.toString(),
          },
        });

        stripeAccountId = account.id;

        // Save Stripe account ID to database
        await this.prisma.user.update({
          where: { id: userId },
          data: { stripeAccountId },
        });

        this.logger.log(`Created Stripe account ${stripeAccountId} for user ${userId}`);
      }

      // Get frontend URLs from environment
      const refreshUrl = this.configService.get<string>('FRONTEND_URL') + '/dashboard/payment';
      const returnUrl = this.configService.get<string>('FRONTEND_URL') + '/dashboard/payment';

      // Generate account link for onboarding or management
      const accountLink = await this.stripe.accountLinks.create({
        account: stripeAccountId,
        type: 'account_onboarding',
        refresh_url: refreshUrl,
        return_url: returnUrl,
      });

      return accountLink.url;
    } catch (error) {
      this.logger.error('Error creating Stripe onboarding link:', error);
      
      // Handle Stripe-specific errors
      if (error.type === 'StripeError') {
        throw new Error(`Stripe error: ${error.message}`);
      }
      
      throw error;
    }
  }

  /**
   * Retrieves payout history for a user with optional period filtering
   * @param userId - ID of the user
   * @param period - Optional period filter ('week' or 'month')
   * @returns Array of payout records
   */
  async getPayoutHistory(
    userId: number,
    period?: 'week' | 'month',
  ): Promise<Payout[]> {
    try {
      const whereClause: any = { userId };

      // Apply period filter if provided
      if (period) {
        const now = new Date();
        let startDate: Date | undefined;

        if (period === 'week') {
          // Get start of current week (Monday)
          startDate = new Date(now);
          const dayOfWeek = now.getDay();
          const diff = (dayOfWeek === 0 ? -6 : 1) - dayOfWeek;
          startDate.setDate(now.getDate() + diff);
          startDate.setHours(0, 0, 0, 0);
        } else if (period === 'month') {
          // Get start of current month
          startDate = new Date(now.getFullYear(), now.getMonth(), 1);
        }

        // Only add date filter if startDate was set
        if (startDate) {
          whereClause.createdAt = {
            gte: startDate,
          };
        }
      }

      // Fetch payouts with filtering and ordering
      const payouts = await this.prisma.payout.findMany({
        where: whereClause,
        orderBy: {
          createdAt: 'desc',
        },
      });

      return payouts;
    } catch (error) {
      this.logger.error('Error fetching payout history:', error);
      throw error;
    }
  }

  /**
   * Helper method to check if user has linked their Stripe account
   * @param userId - ID of the user
   * @returns Boolean indicating if Stripe account is linked
   */
async isStripeAccountLinked(userId: number): Promise<boolean> {
  if (!this.stripe) {
    return false;
  }

  const user = await this.prisma.user.findUnique({
    where: { id: userId },
    select: { stripeAccountId: true },
  });

  if (!user?.stripeAccountId) {
    return false;
  }

  // Check if the account is actually complete in Stripe
  try {
    const account = await this.stripe.accounts.retrieve(user.stripeAccountId);
    // An account is "linked" if it can receive payouts
    return account.charges_enabled && account.payouts_enabled;
  } catch (error) {
    return false;
  }
}
}