import { 
  Controller, 
  Get, 
  Post, 
  Delete, 
  Patch, 
  Body, 
  Param, 
  Query,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { 
  ApiTags, 
  ApiOperation, 
  ApiResponse, 
  ApiBearerAuth,
  ApiParam,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { LearnerPaymentService } from './learner-payment.service';
import { 
  AddPaymentMethodDto, 
  PaymentMethodResponseDto,
  SetupIntentResponseDto,
  UpdatePaymentMethodDto,
} from './dto/add-payment-method.dto';
import { 
  PurchaseHistoryQueryDto, 
  PurchaseHistoryResponseDto,
  CreatePurchaseDto,
  PurchaseResponseDto,
} from './dto/purchase-history.dto';

@ApiTags('Learner Payment')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('api/learner')
export class LearnerPaymentController {
  constructor(private readonly paymentService: LearnerPaymentService) {}

  @Post('payment-methods/setup-intent')
  @ApiOperation({ summary: 'Create Stripe setup intent for adding payment method' })
  @ApiResponse({
    status: 201,
    description: 'Setup intent created successfully',
    type: SetupIntentResponseDto,
  })
  async createSetupIntent(@Request() req): Promise<SetupIntentResponseDto> {
    return this.paymentService.createSetupIntent(req.user.id);
  }

  @Get('payment-methods')
  @ApiOperation({ summary: 'Get all saved payment methods for logged-in user' })
  @ApiResponse({
    status: 200,
    description: 'List of payment methods',
    type: [PaymentMethodResponseDto],
  })
  async getPaymentMethods(@Request() req): Promise<PaymentMethodResponseDto[]> {
    return this.paymentService.getPaymentMethods(req.user.id);
  }

  @Post('payment-methods')
  @ApiOperation({ summary: 'Add new payment method' })
  @ApiResponse({
    status: 201,
    description: 'Payment method added successfully',
    type: PaymentMethodResponseDto,
  })
  @ApiResponse({
    status: 400,
    description: 'Invalid payment method or already exists',
  })
  async addPaymentMethod(
    @Request() req,
    @Body() dto: AddPaymentMethodDto,
  ): Promise<PaymentMethodResponseDto> {
    return this.paymentService.addPaymentMethod(req.user.id, dto);
  }

  @Delete('payment-methods/:id')
  @ApiOperation({ summary: 'Remove payment method' })
  @ApiParam({ name: 'id', description: 'Payment method ID' })
  @ApiResponse({
    status: 204,
    description: 'Payment method removed successfully',
  })
  @ApiResponse({
    status: 404,
    description: 'Payment method not found',
  })
  @HttpCode(HttpStatus.NO_CONTENT)
  async removePaymentMethod(
    @Request() req,
    @Param('id') methodId: string,
  ): Promise<void> {
    return this.paymentService.removePaymentMethod(req.user.id, methodId);
  }

  @Patch('payment-methods/:id/default')
  @ApiOperation({ summary: 'Set payment method as default' })
  @ApiParam({ name: 'id', description: 'Payment method ID' })
  @ApiResponse({
    status: 200,
    description: 'Payment method set as default',
    type: PaymentMethodResponseDto,
  })
  @ApiResponse({
    status: 404,
    description: 'Payment method not found',
  })
  async setDefaultPaymentMethod(
    @Request() req,
    @Param('id') methodId: string,
  ): Promise<PaymentMethodResponseDto> {
    return this.paymentService.setDefaultPaymentMethod(req.user.id, methodId);
  }

  @Get('purchase-history')
  @ApiOperation({ summary: 'Get filtered purchase history' })
  @ApiResponse({
    status: 200,
    description: 'Purchase history retrieved',
    type: PurchaseHistoryResponseDto,
  })
  async getPurchaseHistory(
    @Request() req,
    @Query() query: PurchaseHistoryQueryDto,
  ): Promise<PurchaseHistoryResponseDto> {
    return this.paymentService.getPurchaseHistory(req.user.id, query);
  }

  @Post('purchase-rubies')
  @ApiOperation({ summary: 'Create a new ruby purchase' })
  @ApiResponse({
    status: 201,
    description: 'Purchase created, requires confirmation',
    type: PurchaseResponseDto,
  })
  @ApiResponse({
    status: 400,
    description: 'Invalid purchase amount or payment method',
  })
  async purchaseRubies(
    @Request() req,
    @Body() dto: CreatePurchaseDto,
  ): Promise<PurchaseResponseDto> {
    return this.paymentService.createPurchase(req.user.id, dto);
  }

  @Post('purchase-rubies/:purchaseId/confirm')
  @ApiOperation({ summary: 'Confirm a ruby purchase after payment' })
  @ApiParam({ name: 'purchaseId', description: 'Purchase ID to confirm' })
  @ApiResponse({
    status: 200,
    description: 'Purchase confirmed and rubies added to balance',
  })
  @ApiResponse({
    status: 404,
    description: 'Purchase not found',
  })
  @ApiResponse({
    status: 400,
    description: 'Purchase already completed or payment failed',
  })
  @HttpCode(HttpStatus.OK)
  async confirmPurchase(
    @Request() req,
    @Param('purchaseId') purchaseId: string,
  ): Promise<{ success: boolean; message: string }> {
    await this.paymentService.confirmPurchase(purchaseId, req.user.id);
    return {
      success: true,
      message: 'Purchase confirmed successfully',
    };
  }

  @Get('rubies/balance')
  @ApiOperation({ summary: 'Get current rubies balance' })
  @ApiResponse({
    status: 200,
    description: 'Current rubies balance',
    schema: {
      properties: {
        balance: { type: 'number' },
      },
    },
  })
  async getRubiesBalance(@Request() req): Promise<{ balance: number }> {
    const balance = await this.paymentService.getUserRubiesBalance(req.user.id);
    return { balance };
  }
}