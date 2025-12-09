import { IsEnum, IsInt, Min } from 'class-validator';

export class PurchaseBoostDto {
  @IsEnum(['PROFILE', 'NOTIFY'])
  boostType: 'PROFILE' | 'NOTIFY';

  @IsInt()
  @Min(1)
  quantity: number;

  @IsEnum(['RUBIES', 'PROTEIN'])
  currency: 'RUBIES' | 'PROTEIN';
}