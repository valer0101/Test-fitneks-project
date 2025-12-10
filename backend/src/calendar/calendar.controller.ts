import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Query,
  Param,
  Body,
  Req,
  UseGuards,
  ParseIntPipe,
  HttpCode,
  HttpStatus
} from '@nestjs/common';
import { CalendarService } from './calendar.service';
import { CreateEventDto } from './dto/create-event.dto';
import { UpdateEventDto } from './dto/update-event.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('api/calendar')
export class CalendarController {
  constructor(private readonly calendarService: CalendarService) {}

  // ✅ MOVED TO TOP - Must come before ':id' route
  @Get('attended-events')
  async getAttendedEvents(@Req() req: any) {
    const userId = req.user.id;
    const events = await this.calendarService.getUserAttendedEvents(userId);
    
    return {
      success: true,
      data: events,
    };
  }



  @Get('registered-events')
async getRegisteredEvents(
  @Query('month', ParseIntPipe) month: number,
  @Query('year', ParseIntPipe) year: number,
  @Req() req: any,
) {
  const userId = req.user.id;
  const events = await this.calendarService.getLearnerRegisteredEvents(userId, month, year);
  return {
    success: true,
    data: events,
  };
}




  @Get('range')
  async getEventsByRange(
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
    @Req() req,
  ) {
    return this.calendarService.getEventsByDateRange(
      req.user.id,
      new Date(startDate),
      new Date(endDate),
    );
  }

  @Get()
  async getEvents(
    @Query('month', ParseIntPipe) month: number,
    @Query('year', ParseIntPipe) year: number,
    @Req() req,
  ) {
    return this.calendarService.getEvents(req.user.id, month, year);
  }

  @Get(':id')
  async getEvent(@Param('id') id: string, @Req() req) {
    return this.calendarService.getEvent(id, req.user.id);
  }






  @Post()
  async createEvent(@Body() data: CreateEventDto, @Req() req) {
    return this.calendarService.createEvent(req.user.id, data);
  }

  @Put(':id')
  async updateEvent(
    @Param('id') id: string,
    @Body() data: UpdateEventDto,
    @Req() req,
  ) {
    return this.calendarService.updateEvent(id, req.user.id, data);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  async deleteEvent(@Param('id') id: string, @Req() req) {
    await this.calendarService.deleteEvent(id, req.user.id);
    return { message: 'Event deleted successfully' };
  }
}