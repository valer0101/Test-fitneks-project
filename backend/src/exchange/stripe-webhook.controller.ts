import { Controller, Post, Req, Headers, BadRequestException, type RawBodyRequest } from '@nestjs/common';
import { Request } from 'express';  // ✅ Add this import
import { ExchangeService } from './exchange.service';
import Stripe from 'stripe';

@Controller('webhooks')
export class StripeWebhookController {

  private stripe: Stripe | null = null;

  constructor(private exchangeService: ExchangeService) {
    const secretKey = process.env.STRIPE_SECRET_KEY;
    if (!secretKey || secretKey.trim() === '') {
      console.warn('⚠️  STRIPE_SECRET_KEY is not configured. Stripe webhooks will be disabled.');
      this.stripe = null;
    } else {
      this.stripe = new Stripe(secretKey, {
        apiVersion: '2025-09-30.clover',
      });
    }
  }

  @Post('stripe')
  async handleStripeWebhook(
    @Req() req: RawBodyRequest<Request>,
    @Headers('stripe-signature') signature: string,
  ) {
    if (!this.stripe) {
      throw new BadRequestException('Stripe is not configured');
    }

    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
    if (!webhookSecret) {
      throw new BadRequestException('STRIPE_WEBHOOK_SECRET is not configured');
    }

    let event: Stripe.Event;

    try {
      // ✅ Use rawBody instead of body
      const rawBody = req.rawBody || Buffer.from(req.body);
      
      event = this.stripe.webhooks.constructEvent(
        rawBody,  // ✅ Changed from req.body to rawBody
        signature,
        webhookSecret,
      );
      console.log('✅ Webhook validated:', event.type);
    } catch (err) {
      console.error('❌ Webhook error:', err.message);
      throw new BadRequestException(`Webhook Error: ${err.message}`);
    }

    // Handle successful payment
    if (event.type === 'payment_intent.succeeded') {
      const paymentIntent = event.data.object as Stripe.PaymentIntent;
      if (paymentIntent.metadata.type === 'ruby_purchase') {
        console.log(`💎 Adding ${paymentIntent.metadata.rubies} rubies to user ${paymentIntent.metadata.userId}`);
        await this.exchangeService.confirmRubyPurchase(
          parseInt(paymentIntent.metadata.userId),
          parseInt(paymentIntent.metadata.rubies),
        );
      }
    }

    return { received: true };
  }
}