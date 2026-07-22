import { inject } from '@angular/core';
import { CanActivateChildFn, Router } from '@angular/router';
import { Token } from '../services/token';

export const passwordObligatorioGuard: CanActivateChildFn = (_route, state) => {
  const tokenService = inject(Token);
  const router = inject(Router);

  const rol = String(tokenService.getRol() || '').toUpperCase();
  const debeCambiarPassword = tokenService.debeCambiarPassword();
  const url = state.url || '';

  const estaEnCambioPassword =
    url.startsWith('/cliente/contrasena') ||
    url.startsWith('/cliente/cambiar-password');

  if (rol === 'CLIENTE' && debeCambiarPassword && !estaEnCambioPassword) {
    router.navigate(['/cliente/contrasena']);
    return false;
  }

  return true;
};