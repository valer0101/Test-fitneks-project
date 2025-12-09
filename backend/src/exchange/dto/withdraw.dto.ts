import { IsInt, Min } from 'class-validator';

export class WithdrawDto {
  @IsInt()
  @Min(0)
  shakesToCashOut: number;

  @IsInt()
  @Min(0)
  barsToCashOut: number;
}