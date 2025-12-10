import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Observable } from 'rxjs';

/**
 * Guard that checks if the authenticated user has the required role(s)
 * Works together with @Roles() decorator
 */
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(
    context: ExecutionContext,
  ): boolean | Promise<boolean> | Observable<boolean> {
    // Get the roles required for this route from the @Roles() decorator
    const requiredRoles = this.reflector.getAllAndOverride<string[]>('roles', [
      context.getHandler(),
      context.getClass(),
    ]);

    // If no roles are required, allow access
    if (!requiredRoles || requiredRoles.length === 0) {
      return true;
    }

    // Get the request and user from context
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    // Check if user exists and has a role
    if (!user || !user.role) {
      console.log('RolesGuard: No user or role found');
      return false;
    }

    // Check if user's role matches any of the required roles
    const hasRole = requiredRoles.some((role) => user.role === role);
    
    if (!hasRole) {
      console.log(`RolesGuard: User role "${user.role}" does not match required roles: ${requiredRoles.join(', ')}`);
    }
    
    return hasRole;
  }
}