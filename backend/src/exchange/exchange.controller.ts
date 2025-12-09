import {
  Controller,
  Get,
  Post,
  Body,
  UseGuards,
  Req,
  HttpStatus,
  HttpCode,
} from '@nestjs/common';
import { ExchangeService } from './exchange.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { WithdrawDto } from './dto/withdraw.dto';
import { PurchaseBoostDto } from './dto/purchase-boost.dto';
import { PurchaseRubiesDto } from './dto/purchase-rubies.dto';

@Controller('api/exchange')
@UseGuards(JwtAuthGuard)
export class ExchangeController {
  constructor(private readonly exchangeService: ExchangeService) {}

  @Get('inventory')
  async getInventory(@Req() req) {
    return this.exchangeService.getInventory(req.user.id);
  }

  @Post('withdraw')
  @HttpCode(HttpStatus.OK)
  async withdraw(@Req() req, @Body() dto: WithdrawDto) {
    return this.exchangeService.withdraw(req.user.id, dto);
  }

  @Post('boosts')
  @HttpCode(HttpStatus.OK)
  async purchaseBoost(@Req() req, @Body() dto: PurchaseBoostDto) {
    return this.exchangeService.purchaseBoost(req.user.id, dto);
  }

  @Post('rubies/purchase')
  @HttpCode(HttpStatus.OK)
  async purchaseRubies(@Req() req, @Body() dto: PurchaseRubiesDto) {
    return this.exchangeService.purchaseRubies(req.user.id, dto);
  }
}