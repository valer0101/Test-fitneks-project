import { Module } from '@nestjs/common';
import { PrismaService } from './prisma.service';

@Module({
  providers: [PrismaService],
  exports: [PrismaService], // This line makes the PrismaService available to any other module that imports this PrismaModule
})
export class PrismaModule {}