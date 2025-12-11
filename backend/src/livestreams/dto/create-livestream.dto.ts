import {
  IsString,
  IsEnum,
  IsDateString,
  IsInt,
  IsBoolean,
  IsArray,
  IsObject,
  MaxLength,
  IsOptional,
  Validate,
  ValidateNested,
  Min,
  Max,
  IsIn,
  ValidationArguments,
  ValidatorConstraint,
  ValidatorConstraintInterface,
} from 'class-validator';
import { Type } from 'class-transformer';
import { LiveStreamVisibility, Equipment, WorkoutStyle } from '@prisma/client';

/**
 * Custom validator to ensure NO_EQUIPMENT cannot coexist with other equipment
 */
@ValidatorConstraint({ name: 'NoEquipmentExclusive', async: false })
export class NoEquipmentExclusiveValidator implements ValidatorConstraintInterface {
  validate(equipment: Equipment[]): boolean {
    if (!equipment || equipment.length === 0) return false;
    
    const hasNoEquipment = equipment.includes(Equipment.NO_EQUIPMENT);
    if (hasNoEquipment && equipment.length > 1) {
      return false;
    }
    return true;
  }

  defaultMessage(): string {
    return 'NO_EQUIPMENT cannot be selected with other equipment types';
  }
}

/**
 * Custom validator to ensure scheduledAt is at least 5 minutes in the future
 */
@ValidatorConstraint({ name: 'FutureDate', async: false })
export class FutureDateValidator implements ValidatorConstraintInterface {
  validate(scheduledAt: string, args: ValidationArguments): boolean {
    const dto = args.object as CreateLivestreamDto;
    
    // ✅ Skip validation if going live now
    if (dto.goLiveNow === true) {
      return true;
    }
    
    // ✅ For scheduled streams, enforce 5-minute rule
    const scheduledDate = new Date(scheduledAt);
    const minFutureDate = new Date();
    minFutureDate.setMinutes(minFutureDate.getMinutes() + 5);
    return scheduledDate > minFutureDate;
  }

  defaultMessage(): string {
    return 'Scheduled time must be at least 5 minutes in the future';
  }
}

/**
 * Custom validator for muscle points structure
 * Each muscle group can have 0-5 points representing both intensity and earnable points
 */
@ValidatorConstraint({ name: 'MusclePoints', async: false })
export class MusclePointsValidator implements ValidatorConstraintInterface {
  validate(musclePoints: any): boolean {
    if (!musclePoints || typeof musclePoints !== 'object') return false;
    
    const requiredKeys = ['arms', 'chest', 'back', 'abs', 'legs'];
    const keys = Object.keys(musclePoints);
    
    // Check if all required keys are present and no extra keys
    if (keys.length !== requiredKeys.length || !requiredKeys.every(key => keys.includes(key))) {
      return false;
    }
    
    // Check if all values are integers between 0 and 5
    return Object.values(musclePoints).every(
      value => typeof value === 'number' && 
               Number.isInteger(value) && 
               value >= 0 && 
               value <= 5
    );
  }

  defaultMessage(): string {
    return 'MusclePoints must contain exactly arms, chest, back, abs, legs with integer values 0-5';
  }
}

export class CreateLivestreamDto {
  @IsString()
  @MaxLength(50)
  title: string;

  @IsString()
  @MaxLength(200)
  description: string;

  @IsEnum(LiveStreamVisibility)
  visibility: LiveStreamVisibility;

  @IsDateString()
  @Validate(FutureDateValidator)
  scheduledAt: string;

  @IsInt()
  @IsIn([10, 25, 50, 100, 150, 200])
  maxParticipants: number;

  @IsBoolean()
  @IsOptional()
  isRecurring: boolean = false;

  @IsBoolean()
  @IsOptional()
  goLiveNow?: boolean;


  @IsArray()
  @IsEnum(Equipment, { each: true })
  @Validate(NoEquipmentExclusiveValidator)
  equipmentNeeded: Equipment[];

  @IsEnum(WorkoutStyle)
  workoutStyle: WorkoutStyle;

  @IsInt()
  @IsIn([0, 1, 2, 4, 6, 8, 10])
  @IsOptional()
  giftRequirement: number = 0;

  /**
   * Muscle points represent both workout intensity AND points learners can earn
   * Each muscle group: 0 = no focus/points, 5 = maximum intensity/points
   */
  @IsObject()
  @Validate(MusclePointsValidator)
  musclePoints: {
    arms: number;
    chest: number;
    back: number;
    abs: number;
    legs: number;
  };
}