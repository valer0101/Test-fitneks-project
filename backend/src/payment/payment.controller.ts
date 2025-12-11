import {
  Controller,
  Post,
  Get,
  Query,
  UseGuards,
  Request,
  HttpException,
  HttpStatus,
  Body,
  Headers,
  Req,
} from '@nestjs/common';
import type { RawBodyRequest } from '@nestjs/common'; // ✅ Changed to type import
import { PaymentService } from './payment.service';
import { AuthGuard } from '@nestjs/passport';
import { PayoutQueryDto } from './dto/payout-query.dto';
import { StripeService } from '../stripe/stripe.service';
import { PrismaService } from '../prisma/prisma.service';

@Controller('api/payment')
export class PaymentController {
  constructor(
    private readonly paymentService: PaymentService,
    private readonly stripeService: StripeService,
    private readonly prisma: PrismaService,
  ) {}

  /**
   * Creates or retrieves a Stripe Connect onboarding link
   * @param req - Request object containing authenticated user
   * @returns Object containing the Stripe onboarding URL
   */
  @Post('onboard-stripe')
  async onboardStripe(@Request() req) {
    try {
      const userId = req.user.id;
      const url = await this.paymentService.createStripeOnboardingLink(userId);
      return { url };
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to create Stripe onboarding link',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  /**
   * Retrieves payout history for the authenticated user
   * @param req - Request object containing authenticated user
   * @param query - Optional query parameters for filtering
   * @returns Object containing array of payouts
   */


@Post('purchase-rubies')
  @UseGuards(AuthGuard('jwt'))
  async purchaseRubies(
    @Request() req,
    @Body() body: { rubies: number; amount: number; packageId: string },
  ) {
    try {
      // ✅ Debug logging
      console.log('🔍 Full request user:', JSON.stringify(req.user, null, 2));
      console.log('🔍 Request headers:', req.headers.authorization);
      
      if (!req.user || !req.user.id) {
        console.error('❌ No user in request');
        throw new HttpException(
          'User not authenticated',
          HttpStatus.UNAUTHORIZED,
        );
      }

      const userId = req.user.id;
      console.log('✅ Processing purchase for user:', userId);

      // Create payment intent
      const paymentIntent = await this.stripeService.createPaymentIntent({
        amount: body.amount * 100,
        currency: 'usd',
        metadata: {
          type: 'ruby_purchase',
          userId: userId.toString(),
          rubies: body.rubies.toString(),
          packageId: body.packageId,
        },
      });

      console.log('💳 Payment intent created:', paymentIntent.id);

      return {
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
      };
    } catch (error) {
      console.error('❌ Purchase error:', error.message);
      throw new HttpException(
        error.message || 'Failed to create payment intent',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }


@Post('webhook')
  async handleWebhook(
    @Headers('stripe-signature') signature: string,
    @Body() body: Buffer, // ✅ Changed to Buffer
  ) {
    try {
      // ✅ Use body directly (it's already raw)
      const event = this.stripeService.constructWebhookEvent(
        body,
        signature,
      );

      console.log('🔔 Webhook received:', event.type);

      if (event.type === 'payment_intent.succeeded') {
        const paymentIntent = event.data.object as any;
        console.log('💳 Payment succeeded:', paymentIntent.id);
        console.log('📦 Metadata:', paymentIntent.metadata);

        const userId = parseInt(paymentIntent.metadata.userId);
        const rubies = parseInt(paymentIntent.metadata.rubies);
        const packageId = paymentIntent.metadata.packageId;

        if (!userId || !rubies) {
          console.error('❌ Missing metadata:', { userId, rubies });
          return { received: true };
        }

        // Update user's rubies
        const updatedUser = await this.prisma.user.update({
          where: { id: userId },
          data: {
            rubies: {
              increment: rubies,
            },
          },
        });

        console.log(
          `✅ Added ${rubies} rubies to user ${userId}. New balance: ${updatedUser.rubies}`,
        );

        // Create purchase history
        await this.prisma.rubyPurchase.create({
          data: {
            userId,
            rubiesAmount: rubies,
            costCents: paymentIntent.amount,
            stripePaymentIntentId: paymentIntent.id,
            status: 'completed',
            metadata: {
              packageId: packageId || 'unknown',
            },
          },
        });

        console.log('💾 Purchase history saved');
      }

      return { received: true };
    } catch (error) {
      console.error('❌ Webhook error:', error);
      throw new HttpException(
        'Webhook processing failed',
        HttpStatus.BAD_REQUEST,
      );
    }
  }


  


  @Get('payouts')
  @UseGuards(AuthGuard('jwt')) 
  async getPayouts(@Request() req, @Query() query: PayoutQueryDto) {
    try {
      const userId = req.user.id;
      const payouts = await this.paymentService.getPayoutHistory(
        userId,
        query.period,
      );
      return { payouts };
    } catch (error) {
      throw new HttpException(
        error.message || 'Failed to retrieve payout history',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

@Get('stripe-status')
@UseGuards(AuthGuard('jwt'))
async checkStripeStatus(@Request() req) {
  const isLinked = await this.paymentService.isStripeAccountLinked(req.user.id);
  return { isLinked };
}



}