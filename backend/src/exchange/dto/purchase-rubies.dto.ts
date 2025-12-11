import { IsString, IsInt, Min } from 'class-validator';

export class PurchaseRubiesDto {
  @IsString()
  packageId: string;

  @IsInt()
  @Min(1)
  amount: number;
}