import { IsOptional, IsIn } from 'class-validator';

export class PayoutQueryDto {
  @IsOptional()
  @IsIn(['week', 'month'])
  period?: 'week' | 'month';
}