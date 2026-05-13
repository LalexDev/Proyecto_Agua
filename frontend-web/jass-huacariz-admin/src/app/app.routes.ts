import { Routes } from '@angular/router';

import { Login } from './pages/login/login';

import { AdminLayout } from './layout/admin-layout/admin-layout';
import { ClienteLayout } from './layout/cliente-layout/cliente-layout';

import { Dashboard } from './pages/admin/dashboard/dashboard';
import { Clientes } from './pages/admin/clientes/clientes';
import { Recibos } from './pages/admin/recibos/recibos';
import { Pagos } from './pages/admin/pagos/pagos';
import { Reportes } from './pages/admin/reportes/reportes';
import { Tarifas } from './pages/admin/tarifas/tarifas';

import { Inicio } from './pages/cliente/inicio/inicio';
import { MisRecibos } from './pages/cliente/mis-recibos/mis-recibos';
import { DetalleRecibo } from './pages/cliente/detalle-recibo/detalle-recibo';
import { PagarRecibo } from './pages/cliente/pagar-recibo/pagar-recibo';
import { Perfil } from './pages/cliente/perfil/perfil';
import { CambiarPassword } from './pages/cliente/cambiar-password/cambiar-password';

import { authGuard } from './core/guards/auth-guard';
import { roleGuard } from './core/guards/role-guard';

export const routes: Routes = [
  {
    path: '',
    redirectTo: 'login',
    pathMatch: 'full'
  },
  {
    path: 'login',
    component: Login
  },
  {
    path: 'admin',
    component: AdminLayout,
    canActivate: [authGuard, roleGuard],
    data: { roles: ['ADMIN'] },
    children: [
      { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
      { path: 'dashboard', component: Dashboard },
      { path: 'clientes', component: Clientes },
      { path: 'recibos', component: Recibos },
      { path: 'pagos', component: Pagos },
      { path: 'reportes', component: Reportes },
      { path: 'tarifas', component: Tarifas }
    ]
  },
  {
    path: 'cliente',
    component: ClienteLayout,
    canActivate: [authGuard, roleGuard],
    data: { roles: ['CLIENTE'] },
    children: [
      { path: '', redirectTo: 'inicio', pathMatch: 'full' },
      { path: 'inicio', component: Inicio },
      { path: 'mis-recibos', component: MisRecibos },
      { path: 'detalle-recibo/:id', component: DetalleRecibo },
      { path: 'pagar-recibo/:id', component: PagarRecibo },
      { path: 'perfil', component: Perfil },
      { path: 'cambiar-password', component: CambiarPassword }
    ]
  },
  {
    path: '**',
    redirectTo: 'login'
  }
];