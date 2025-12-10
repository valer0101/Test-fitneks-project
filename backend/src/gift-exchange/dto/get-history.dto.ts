import { IsEnum, IsOptional } from 'class-validator';

export enum HistoryPeriod {
  WEEK = 'week',
  MONTH = 'month',
}

export class GetHistoryDto {
  @IsOptional()
  @IsEnum(HistoryPeriod, { message: 'Period must be either "week" or "month"' })
  period?: HistoryPeriod = HistoryPeriod.WEEK;
}