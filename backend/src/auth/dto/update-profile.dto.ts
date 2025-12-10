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

export class UpdateTrainerProfileDto {
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
  @MaxLength(150)
  @IsOptional()
  bio?: string;

  @IsString()
  @IsNotEmpty()
  location: string;

  @IsString()
  @IsNotEmpty()
  timezone: string;

  @IsEnum(WorkoutType, { each: true })
  @ArrayMinSize(1)
  workoutTypes: WorkoutType[];

    @IsOptional()
    @IsEnum(Goal, { each: true })
    goals: Goal[]; // <-- Correct

    @IsOptional()
    @IsEnum(MuscleGroup, { each: true })
    muscleGroups: MuscleGroup[]; // <-- Correct

}