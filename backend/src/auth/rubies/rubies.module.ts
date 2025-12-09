import { Module } from '@nestjs/common';
import { RubiesController } from './rubies.controller';
import { RubiesService } from './rubies.service';
import { PrismaModule } from '../../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [RubiesController],
  providers: [RubiesService],
  exports: [RubiesService],
})
export class RubiesModule {}