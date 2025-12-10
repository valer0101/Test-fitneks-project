import { Injectable, OnModuleInit } from '@nestjs/common';
import Stripe from 'stripe';

@Injectable()
export class StripeService implements OnModuleInit {
  private stripe: Stripe | null = null;

  onModuleInit() {
    const secretKey = process.env.STRIPE_SECRET_KEY;
    if (!secretKey || secretKey.trim() === '') {
      console.warn('⚠️  STRIPE_SECRET_KEY is not configured. Stripe features will be disabled.');
      this.stripe = null;
      return;
    }
    this.stripe = new Stripe(secretKey, {
      apiVersion: '2025-09-30.clover',
    });
  }

  // ✅ ADD THIS METHOD
  constructWebhookEvent(rawBody: Buffer, signature: string) {
    if (!this.stripe) {
      throw new Error('Stripe is not configured');
    }
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
    if (!webhookSecret) {
      throw new Error('STRIPE_WEBHOOK_SECRET is not defined in environment variables');
    }
    return this.stripe.webhooks.constructEvent(
      rawBody,
      signature,
      webhookSecret,
    );
  }

  // Create payment intent for buying rubies
  async createPaymentIntent(params: {
    amount: number;
    currency: string;
    metadata: Record<string, string>;
  }) {
    if (!this.stripe) {
      throw new Error('Stripe is not configured');
    }
    return this.stripe.paymentIntents.create({
      amount: params.amount,
      currency: params.currency,
      metadata: params.metadata,
      automatic_payment_methods: {
        enabled: true,
      },
    });
  }

  // Create payout for withdrawals (requires Stripe Connect)
  async createPayout(params: {
    amount: number;
    stripeAccountId: string;
  }) {
    if (!this.stripe) {
      throw new Error('Stripe is not configured');
    }
    return this.stripe.transfers.create({
      amount: params.amount,
      currency: 'usd',
      destination: params.stripeAccountId,
    });
  }
}