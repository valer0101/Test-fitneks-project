import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { LearnerPaymentController } from './learner-payment.controller';
import { LearnerPaymentService } from './learner-payment.service';
import { PrismaModule } from '../prisma/prisma.module'; // Adjust to your PrismaModule path

@Module({
  imports: [ConfigModule, PrismaModule],
  controllers: [LearnerPaymentController],
  providers: [LearnerPaymentService],
  exports: [LearnerPaymentService],
})
export class LearnerPaymentModule {}