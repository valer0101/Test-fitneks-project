import { EventType, EventStatus } from '@prisma/client';

export class CreateEventDto {
  type: EventType;
  status: EventStatus;
  title: string;
  date: Date;
  maxParticipants?: number;
  ticketValue?: number;
  equipment: string[];
  trainingType: string;
  pointsBreakdown?: any;
  duration: number;
}