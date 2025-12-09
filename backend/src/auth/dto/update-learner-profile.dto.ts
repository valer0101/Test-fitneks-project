// backend/src/auth/dto/update-learner-profile.dto.ts

import {
  IsString,
  IsNotEmpty,
  MaxLength,
  IsAlphanumeric,
  IsOptional,
  IsEnum,
  ArrayMinSize,
} from 'class-validator';
import { WorkoutType, Goal, MuscleGroup } from '@prisma/client';

export class UpdateLearnerProfileDto {
  // --- MANDATORY FIELDS ---
  @IsString()
  @IsNotEmpty()
  @MaxLength(30)
  @IsAlphanumeric()
  username: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(30)
  displayName: string;

  @IsString()
  @IsNotEmpty()
  location: string;

  @IsString()
  @IsNotEmpty()
  timezone: string;

  @IsEnum(WorkoutType, { each: true })
  @ArrayMinSize(1)
  workoutTypes: WorkoutType[];

  // --- OPTIONAL FIELDS ---
  @IsString()
  @MaxLength(150)
  @IsOptional()
  bio?: string;

  @IsOptional()
  @IsEnum(Goal, { each: true })
  goals?: Goal[];

  @IsOptional()
  @IsEnum(MuscleGroup, { each: true })
  muscleGroups?: MuscleGroup[];
}