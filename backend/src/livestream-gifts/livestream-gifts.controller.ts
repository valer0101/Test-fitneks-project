import {
  Controller,
  Post,
  Body,
  UseGuards,
  Request,
  HttpStatus,
  HttpException,
  Logger,
} from '@nestjs/common';
import { LivestreamGiftsService } from './livestream-gifts.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('api/gifts')
@UseGuards(JwtAuthGuard)
export class LivestreamGiftsController {
  private readonly logger = new Logger(LivestreamGiftsController.name);

  constructor(private readonly livestreamGiftsService: LivestreamGiftsService) {}

  @Post('send')
  async sendGift(
    @Body() 
    body: { 
      livestreamId: string; 
      giftType: string; 
      cost: number;
      quantity?: number; // ✅ Added quantity parameter
    },
    @Request() req,
  ) {
    // CRITICAL FIX: Better validation and logging
    this.logger.log(
      `Gift send request from user ${req.user.id}: ${JSON.stringify(body)}`
    );

    try {
      // Validate required fields
      if (!body.livestreamId || !body.giftType || body.cost === undefined) {
        throw new HttpException(
          'Missing required fields: livestreamId, giftType, cost',
          HttpStatus.BAD_REQUEST
        );
      }

      // Validate quantity if provided
      if (body.quantity !== undefined && body.quantity < 1) {
        throw new HttpException(
          'Quantity must be at least 1',
          HttpStatus.BAD_REQUEST
        );
      }

      const result = await this.livestreamGiftsService.sendGift(
        req.user.id,
        body.livestreamId,
        body.giftType,
        body.cost,
        body.quantity,
      );

      this.logger.log(
        `Gift sent successfully: ${result.gift.quantity}x ${result.gift.giftType} by user ${req.user.id}`
      );

      return result;
    } catch (error) {
      this.logger.error(
        `Failed to send gift: ${error.message}`,
        error.stack
      );
      
      // Re-throw HttpExceptions as-is
      if (error instanceof HttpException) {
        throw error;
      }
      
      // Wrap other errors
      throw new HttpException(
        'Internal server error while sending gift',
        HttpStatus.INTERNAL_SERVER_ERROR
      );
    }
  }
}