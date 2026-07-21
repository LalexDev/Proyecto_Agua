import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { Token } from '../services/token';

export const roleGuard: CanActivateFn = (route) => {
  const tokenService = inject(Token);
  const router = inject(Router);

  const rolActual = tokenService.getRol();
  const rolesPermitidos = route.data?.['roles'] as string[];

  if (rolActual && rolesPermitidos.includes(rolActual)) {
    return true;
  }

  router.navigate(['/login']);
  return false;
};
