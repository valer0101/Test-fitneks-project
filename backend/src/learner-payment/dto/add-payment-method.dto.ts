import { IsString, IsNotEmpty, IsOptional, IsBoolean } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class AddPaymentMethodDto {
  @ApiProperty({
    description: 'Stripe payment method ID from client-side tokenization',
    example: 'pm_1234567890',
  })
  @IsString()
  @IsNotEmpty()
  paymentMethodId: string;

  @ApiProperty({
    description: 'Set this payment method as default',
    example: true,
    required: false,
  })
  @IsBoolean()
  @IsOptional()
  setAsDefault?: boolean;
}

export class UpdatePaymentMethodDto {
  @ApiProperty({
    description: 'Set this payment method as default',
    example: true,
  })
  @IsBoolean()
  @IsNotEmpty()
  isDefault: boolean;
}

export class PaymentMethodResponseDto {
  id: string;
  cardBrand: string;
  cardLast4: string;
  cardExpMonth: number;
  cardExpYear: number;
  isDefault: boolean;
  createdAt: Date;
}

export class SetupIntentResponseDto {
  @ApiProperty({
    description: 'Stripe setup intent client secret',
    example: 'seti_1234567890_secret_1234567890',
  })
  clientSecret: string;

  @ApiProperty({
    description: 'Stripe customer ID',
    example: 'cus_1234567890',
  })
  customerId: string;
}