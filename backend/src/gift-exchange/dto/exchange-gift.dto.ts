import { IsEnum, IsInt, IsPositive } from 'class-validator';
import { GiftType, CurrencyType } from '@prisma/client';

export class ExchangeGiftDto {
  @IsEnum(GiftType, { message: 'Invalid gift type' })
  giftType: GiftType;

  @IsInt()
  @IsPositive({ message: 'Quantity must be a positive number' })
  quantity: number;

  @IsEnum(CurrencyType, { message: 'Invalid currency type' })
  currencyUsed: CurrencyType;
}