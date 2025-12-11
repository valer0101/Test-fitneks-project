import { Module } from '@nestjs/common';
import { GiftExchangeController } from './gift-exchange.controller';
import { GiftExchangeService } from './gift-exchange.service';
import { PrismaModule } from '../prisma/prisma.module'; // Adjust path as needed

@Module({
  imports: [PrismaModule],
  controllers: [GiftExchangeController],
  providers: [GiftExchangeService],
  exports: [GiftExchangeService],
})
export class GiftExchangeModule {}