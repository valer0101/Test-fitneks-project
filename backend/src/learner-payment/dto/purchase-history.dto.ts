import { IsEnum, IsOptional, IsInt, Min, Max, IsString, IsNotEmpty } from 'class-validator';
import { Transform } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

export enum PurchasePeriod {
  WEEK = 'week',
  MONTH = 'month',
  ALL = 'all',
}

export class PurchaseHistoryQueryDto {
  @ApiProperty({
    description: 'Filter purchases by time period',
    enum: PurchasePeriod,
    required: false,
    default: PurchasePeriod.MONTH,
  })
  @IsEnum(PurchasePeriod)
  @IsOptional()
  period?: PurchasePeriod = PurchasePeriod.MONTH;

  @ApiProperty({
    description: 'Page number for pagination',
    minimum: 1,
    default: 1,
    required: false,
  })
  @Transform(({ value }) => parseInt(value))
  @IsInt()
  @Min(1)
  @IsOptional()
  page?: number = 1;

  @ApiProperty({
    description: 'Number of items per page',
    minimum: 1,
    maximum: 100,
    default: 20,
    required: false,
  })
  @Transform(({ value }) => parseInt(value))
  @IsInt()
  @Min(1)
  @Max(100)
  @IsOptional()
  limit?: number = 20;
}

export class PurchaseHistoryItemDto {
  id: string;
  rubiesAmount: number;
  costCents: number;
  status: string;
  paymentMethodLast4: string;
  paymentMethodBrand: string;
  createdAt: Date;
}

export class PurchaseHistoryResponseDto {
  @ApiProperty({ type: [PurchaseHistoryItemDto] })
  purchases: PurchaseHistoryItemDto[];

  @ApiProperty({ description: 'Total number of purchases' })
  total: number;

  @ApiProperty({ description: 'Current page' })
  page: number;

  @ApiProperty({ description: 'Total pages' })
  totalPages: number;

  @ApiProperty({ description: 'Total rubies purchased in period' })
  totalRubies: number;

  @ApiProperty({ description: 'Total amount spent in cents' })
  totalSpentCents: number;
}

export class CreatePurchaseDto {
 @ApiProperty({
description: 'Number of rubies to purchase',
example: 100,
 })
 @IsInt()
 @Min(1)
rubiesAmount: number;
 @ApiProperty({
description: 'Payment method ID to use (optional for inline payments)',
example: 'pm_1234567890',
required: false,
 })
 @IsString()
 @IsOptional()
paymentMethodId?: string;
}

export class PurchaseResponseDto {
  @ApiProperty({ description: 'Purchase ID' })
  id: string;

  @ApiProperty({ description: 'Stripe payment intent client secret for confirmation' })
  clientSecret: string;

  @ApiProperty({ description: 'Purchase status' })
  status: string;

  @ApiProperty({ description: 'Amount of rubies being purchased' })
  rubiesAmount: number;

  @ApiProperty({ description: 'Cost in cents' })
  costCents: number;
}