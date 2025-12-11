import { 
  Controller, 
  Get, 
  Post, 
  Body, 
  Query, 
  UseGuards 
} from '@nestjs/common';
import { GiftExchangeService } from './gift-exchange.service';
import { ExchangeGiftDto } from './dto/exchange-gift.dto';
import { GetHistoryDto, HistoryPeriod } from './dto/get-history.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { GetUser } from '../auth/decorator/get-user.decorator';
import type { User } from '@prisma/client'; // ✅ Changed to 'import type'

@Controller('api/gift-exchange')
@UseGuards(JwtAuthGuard)
export class GiftExchangeController {
  constructor(private readonly giftExchangeService: GiftExchangeService) {}

  /**
   * GET /api/gift-exchange/balances
   * Fetch the current user's currency and gift balances
   */
  @Get('balances')
  async getBalances(@GetUser() user: User) {
    return this.giftExchangeService.getBalances(user.id);
  }

  /**
   * POST /api/gift-exchange/exchange
   * Purchase gifts using tokens or rubies
   */
  @Post('exchange')
  async exchangeGift(
    @GetUser() user: User,
    @Body() dto: ExchangeGiftDto,
  ) {
    return this.giftExchangeService.exchangeGift(user.id, dto);
  }

  /**
   * GET /api/gift-exchange/history
   * Fetch user's gift purchase history
   */
  @Get('history')
  async getHistory(
    @GetUser() user: User,
    @Query('period') period?: HistoryPeriod,
  ) {
    return this.giftExchangeService.getHistory(
      user.id, 
      period || HistoryPeriod.WEEK
    );
  }
}