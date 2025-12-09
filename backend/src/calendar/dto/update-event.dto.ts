import { EventType, EventStatus } from '@prisma/client';

export class UpdateEventDto {
  type?: EventType;
  status?: EventStatus;
  title?: string;
  date?: Date;
  maxParticipants?: number;
  ticketValue?: number;
  giftsReceived?: number;
  xpEarned?: number;
  equipment?: string[];
  trainingType?: string;
  pointsBreakdown?: any;
  duration?: number;
}