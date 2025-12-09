import { Injectable, NotFoundException, BadRequestException, InternalServerErrorException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';
import { 
  AddPaymentMethodDto, 
  PaymentMethodResponseDto,
  SetupIntentResponseDto,
} from './dto/add-payment-method.dto';
import { 
  PurchaseHistoryQueryDto, 
  PurchaseHistoryResponseDto,
  PurchasePeriod,
  CreatePurchaseDto,
  PurchaseResponseDto,
} from './dto/purchase-history.dto';

@Injectable()
export class LearnerPaymentService {
  private stripe: Stripe;

  constructor(
    private prisma: PrismaService,
    private configService: ConfigService,
  ) {
    const stripeKey = this.configService.get<string>('STRIPE_SECRET_KEY');
    if (!stripeKey) {
      throw new Error('STRIPE_SECRET_KEY not configured');
    }
    this.stripe = new Stripe(stripeKey, {
      apiVersion: '2025-09-30.clover',
    });
  }

  // Ruby pricing tiers
  private getRubyPricing(rubies: number): number {
  const pricingTiers = [
    { rubies: 3, price: 199 },    // $1.99
    { rubies: 9, price: 499 },    // $4.99
    { rubies: 15, price: 699 },   // $6.99
    { rubies: 30, price: 1299 },  // $12.99
    { rubies: 60, price: 2499 },  // $24.99
    { rubies: 120, price: 4899 }, // $48.99
    { rubies: 240, price: 9699 }, // $96.99
    { rubies: 480, price: 19299 }, // $192.99
  ];

  const tier = pricingTiers.find(t => t.rubies === rubies);
  if (!tier) {
    throw new BadRequestException('Invalid ruby amount');
  }
  return tier.price;
}

  async createSetupIntent(userId: number): Promise<SetupIntentResponseDto> {
    try {
      const user = await this.prisma.user.findUnique({ where: { id: userId } });
      if (!user) {
        throw new NotFoundException('User not found');
      }

      // Create or retrieve Stripe customer
      let customerId = user.stripeCustomerId;
      if (!customerId) {
        const customer = await this.stripe.customers.create({
          email: user.email,
          name: user.displayName,
          metadata: {
            userId: userId.toString(),
            userType: 'learner',
          },
        });
        customerId = customer.id;

        // Save customer ID to user
        await this.prisma.user.update({
          where: { id: userId },
          data: { stripeCustomerId: customerId },
        });
      }

      // Create setup intent for saving card
      const setupIntent = await this.stripe.setupIntents.create({
        customer: customerId,
        payment_method_types: ['card'],
        usage: 'off_session',
        metadata: {
          userId: userId.toString(),
        },
      });

      if (!setupIntent.client_secret) {
        throw new InternalServerErrorException('Failed to create setup intent');
      }

      return {
        clientSecret: setupIntent.client_secret,
        customerId: customerId,
      };
    } catch (error) {
      this.handleStripeError(error);
    }
  }

  async addPaymentMethod(
    userId: number,
    dto: AddPaymentMethodDto,
  ): Promise<PaymentMethodResponseDto> {
    try {
      const user = await this.prisma.user.findUnique({ where: { id: userId } });
      if (!user || !user.stripeCustomerId) {
        throw new BadRequestException('User not found or no Stripe customer');
      }

      // Retrieve payment method details from Stripe
      const stripePaymentMethod = await this.stripe.paymentMethods.retrieve(
        dto.paymentMethodId,
      );

      // Attach payment method to customer if not already attached
      if (stripePaymentMethod.customer !== user.stripeCustomerId) {
        await this.stripe.paymentMethods.attach(dto.paymentMethodId, {
          customer: user.stripeCustomerId,
        });
      }

      // Check if this payment method already exists
      const existingMethod = await this.prisma.learnerPaymentMethod.findUnique({
        where: { stripePaymentMethodId: dto.paymentMethodId },
      });

      if (existingMethod) {
        throw new BadRequestException('Payment method already added');
      }

      // If setting as default, unset all other defaults
      if (dto.setAsDefault) {
        await this.prisma.learnerPaymentMethod.updateMany({
          where: { userId: userId },
          data: { isDefault: false },
        });
      }

      // Create payment method record
      const paymentMethod = await this.prisma.learnerPaymentMethod.create({
        data: {
          userId: userId,
          stripePaymentMethodId: dto.paymentMethodId,
          cardBrand: stripePaymentMethod.card?.brand,
          cardLast4: stripePaymentMethod.card?.last4,
          cardExpMonth: stripePaymentMethod.card?.exp_month,
          cardExpYear: stripePaymentMethod.card?.exp_year,
          isDefault: dto.setAsDefault || false,
        },
      });

      return this.mapToPaymentMethodResponse(paymentMethod);
    } catch (error) {
      this.handleStripeError(error);
    }
  }

  async getPaymentMethods(userId: number): Promise<PaymentMethodResponseDto[]> {
    const methods = await this.prisma.learnerPaymentMethod.findMany({
      where: { userId: userId },
      orderBy: [{ isDefault: 'desc' }, { createdAt: 'desc' }],
    });

    return methods.map(method => this.mapToPaymentMethodResponse(method));
  }

  async removePaymentMethod(userId: number, methodId: string): Promise<void> {
    const method = await this.prisma.learnerPaymentMethod.findFirst({
      where: { id: methodId, userId: userId },
    });

    if (!method) {
      throw new NotFoundException('Payment method not found');
    }

    try {
      // Detach from Stripe customer
      await this.stripe.paymentMethods.detach(method.stripePaymentMethodId);
      
      // Delete from database
      await this.prisma.learnerPaymentMethod.delete({ where: { id: methodId } });

      // If this was default, set another as default
      if (method.isDefault) {
        const remainingMethods = await this.prisma.learnerPaymentMethod.findMany({
          where: { userId: userId },
          orderBy: { createdAt: 'desc' },
          take: 1,
        });

        if (remainingMethods.length > 0) {
          await this.prisma.learnerPaymentMethod.update({
            where: { id: remainingMethods[0].id },
            data: { isDefault: true },
          });
        }
      }
    } catch (error) {
      this.handleStripeError(error);
    }
  }

  async setDefaultPaymentMethod(
    userId: number,
    methodId: string,
  ): Promise<PaymentMethodResponseDto> {
    const method = await this.prisma.learnerPaymentMethod.findFirst({
      where: { id: methodId, userId: userId },
    });

    if (!method) {
      throw new NotFoundException('Payment method not found');
    }

    // Unset all other defaults
    await this.prisma.learnerPaymentMethod.updateMany({
      where: { userId: userId },
      data: { isDefault: false },
    });

    // Set this as default
    const updated = await this.prisma.learnerPaymentMethod.update({
      where: { id: methodId },
      data: { isDefault: true },
    });

    // Update Stripe customer default payment method
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (user?.stripeCustomerId) {
      await this.stripe.customers.update(user.stripeCustomerId, {
        invoice_settings: {
          default_payment_method: method.stripePaymentMethodId,
        },
      });
    }

    return this.mapToPaymentMethodResponse(updated);
  }

  async createPurchase(
  userId: number,
  dto: CreatePurchaseDto,
): Promise<PurchaseResponseDto> {
  try {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new BadRequestException('User not found');
    }

    // Create or get Stripe customer
    let customerId = user.stripeCustomerId;
    if (!customerId) {
      const customer = await this.stripe.customers.create({
        email: user.email,
        name: user.displayName,
        metadata: { userId: userId.toString() },
      });
      customerId = customer.id;
      
      await this.prisma.user.update({
        where: { id: userId },
        data: { stripeCustomerId: customerId },
      });
    }

    const costCents = this.getRubyPricing(dto.rubiesAmount);

    let paymentIntent;
    let paymentMethod: { id: string; stripePaymentMethodId: string } | null = null;

    // Check if using saved payment method or inline payment
    if (dto.paymentMethodId) {
      // EXISTING FLOW: Use saved payment method
      paymentMethod = await this.prisma.learnerPaymentMethod.findFirst({
        where: { id: dto.paymentMethodId, userId: userId },
      });

      if (!paymentMethod) {
        throw new NotFoundException('Payment method not found');
      }

      paymentIntent = await this.stripe.paymentIntents.create({
        amount: costCents,
        currency: 'usd',
        customer: customerId,
        payment_method: paymentMethod.stripePaymentMethodId,
        payment_method_types: ['card'],
        confirmation_method: 'manual',
        confirm: false,
        metadata: {
          userId: userId.toString(),
          rubiesAmount: dto.rubiesAmount.toString(),
          purchaseType: 'rubies',
        },
        description: `Purchase of ${dto.rubiesAmount} rubies`,
      });
    } else {
      // NEW FLOW: Inline payment (no saved payment method)
      paymentIntent = await this.stripe.paymentIntents.create({
        amount: costCents,
        currency: 'usd',
        customer: customerId,
        payment_method_types: ['card'],
        confirmation_method: 'automatic',
        metadata: {
          userId: userId.toString(),
          rubiesAmount: dto.rubiesAmount.toString(),
          purchaseType: 'rubies',
        },
        description: `Purchase of ${dto.rubiesAmount} rubies`,
      });
    }

    if (!paymentIntent.client_secret) {
      throw new InternalServerErrorException('Failed to create payment intent');
    }

    // Create purchase record
    const purchase = await this.prisma.rubyPurchase.create({
      data: {
        userId: userId,
        rubiesAmount: dto.rubiesAmount,
        costCents: costCents,
        stripePaymentIntentId: paymentIntent.id,
        paymentMethodId: paymentMethod?.id || null,
        status: 'pending',
        metadata: {
          stripeCustomerId: customerId,
          email: user.email,
        },
      },
    });

    return {
      id: purchase.id,
      clientSecret: paymentIntent.client_secret,
      status: purchase.status,
      rubiesAmount: purchase.rubiesAmount,
      costCents: purchase.costCents,
    };
  } catch (error) {
    this.handleStripeError(error);
  }
}

  async confirmPurchase(purchaseId: string, userId: number): Promise<void> {
    const purchase = await this.prisma.rubyPurchase.findFirst({
      where: { id: purchaseId, userId: userId },
    });

    if (!purchase) {
      throw new NotFoundException('Purchase not found');
    }

    if (purchase.status === 'completed') {
      throw new BadRequestException('Purchase already completed');
    }

    if (!purchase.stripePaymentIntentId) {
      throw new BadRequestException('Invalid purchase - no payment intent');
    }

    // Verify payment intent status with Stripe
    const paymentIntent = await this.stripe.paymentIntents.retrieve(
      purchase.stripePaymentIntentId,
    );

    if (paymentIntent.status !== 'succeeded') {
      throw new BadRequestException('Payment not successful');
    }

    // Update purchase status and user rubies in transaction
    await this.prisma.$transaction(async (tx) => {
      // Update purchase status
      await tx.rubyPurchase.update({
        where: { id: purchaseId },
        data: { status: 'completed' },
      });

      // Update or create user rubies balance
      const userRubies = await tx.userRubies.findUnique({
        where: { userId: userId },
      });

      if (userRubies) {
        await tx.userRubies.update({
          where: { userId: userId },
          data: {
            balance: { increment: purchase.rubiesAmount },
            totalPurchased: { increment: purchase.rubiesAmount },
          },
        });
      } else {
        await tx.userRubies.create({
          data: {
            userId: userId,
            balance: purchase.rubiesAmount,
            totalPurchased: purchase.rubiesAmount,
            totalSpent: 0,
          },
        });
      }
    
    // ✅ Add this line inside the transaction:
await tx.user.update({
  where: { id: userId },
  data: { rubies: { increment: purchase.rubiesAmount } },
});
    
    
    });
  }

  async getPurchaseHistory(
    userId: number,
    query: PurchaseHistoryQueryDto,
  ): Promise<PurchaseHistoryResponseDto> {
    const { period, page = 1, limit = 20 } = query;

    // Calculate date filter
    const now = new Date();
    let dateFilter = {};
    
    if (period === PurchasePeriod.WEEK) {
      const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
      dateFilter = { createdAt: { gte: weekAgo } };
    } else if (period === PurchasePeriod.MONTH) {
      const monthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
      dateFilter = { createdAt: { gte: monthAgo } };
    }

    // Get purchases with pagination
    const [purchases, total] = await Promise.all([
      this.prisma.rubyPurchase.findMany({
        where: {
          userId: userId,
          status: 'completed',
          ...dateFilter,
        },
        include: { paymentMethod: true },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.rubyPurchase.count({
        where: {
          userId: userId,
          status: 'completed',
          ...dateFilter,
        },
      }),
    ]);

    // Calculate totals for period
    const totals = await this.prisma.rubyPurchase.aggregate({
      where: {
        userId: userId,
        status: 'completed',
        ...dateFilter,
      },
      _sum: {
        rubiesAmount: true,
        costCents: true,
      },
    });

    return {
      purchases: purchases.map(p => ({
        id: p.id,
        rubiesAmount: p.rubiesAmount,
        costCents: p.costCents,
        status: p.status,
        paymentMethodLast4: p.paymentMethod?.cardLast4 || 'N/A',
        paymentMethodBrand: p.paymentMethod?.cardBrand || 'N/A',
        createdAt: p.createdAt,
      })),
      total,
      page,
      totalPages: Math.ceil(total / limit),
      totalRubies: totals._sum.rubiesAmount || 0,
      totalSpentCents: totals._sum.costCents || 0,
    };
  }

  async getUserRubiesBalance(userId: number): Promise<number> {
    const userRubies = await this.prisma.userRubies.findUnique({
      where: { userId: userId },
    });

    return userRubies?.balance || 0;
  }

  private mapToPaymentMethodResponse(method: any): PaymentMethodResponseDto {
    return {
      id: method.id,
      cardBrand: method.cardBrand,
      cardLast4: method.cardLast4,
      cardExpMonth: method.cardExpMonth,
      cardExpYear: method.cardExpYear,
      isDefault: method.isDefault,
      createdAt: method.createdAt,
    };
  }

  private handleStripeError(error: any): never {
    if (error.type === 'StripeCardError') {
      throw new BadRequestException(`Card error: ${error.message}`);
    } else if (error.type === 'StripeInvalidRequestError') {
      throw new BadRequestException(`Invalid request: ${error.message}`);
    } else if (error.type === 'StripeAPIError') {
      throw new InternalServerErrorException('Payment service error');
    } else if (error.type === 'StripeConnectionError') {
      throw new InternalServerErrorException('Network error');
    } else if (error.type === 'StripeAuthenticationError') {
      throw new InternalServerErrorException('Authentication error');
    } else if (error instanceof BadRequestException || error instanceof NotFoundException) {
      throw error;
    } else {
      throw new InternalServerErrorException('An unexpected error occurred');
    }
  }
}