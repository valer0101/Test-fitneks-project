import { SetMetadata } from '@nestjs/common';

/**
 * Decorator to specify which roles can access a route
 * Usage: @Roles('Trainer', 'Admin')
 */
export const Roles = (...roles: string[]) => SetMetadata('roles', roles);