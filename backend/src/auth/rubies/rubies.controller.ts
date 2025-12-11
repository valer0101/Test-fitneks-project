import {
  Controller,
  Post,
  Body,
  UseGuards,
  Request,
  HttpStatus,
  HttpException,
  Logger,
} from '@nestjs/common';
import { RubiesService } from './rubies.service';
import { JwtAuthGuard } from '../jwt-auth.guard';

@Controller('api/rubies')
@UseGuards(JwtAuthGuard)
export class RubiesController {
  private readonly logger = new Logger(RubiesController.name);

  constructor(private readonly rubiesService: RubiesService) {}

  @Post('transfer')
  async transferRubies(
    @Body() body: { livestreamId: string; amount: number },
    @Request() req,
  ) {
    this.logger.log(`User ${req.user.id} transferring ${body.amount} rubies to livestream ${body.livestreamId}`);
    
    return this.rubiesService.transferRubies(
      req.user.id,
      body.livestreamId,
      body.amount,
    );
  }
}