import { Routes } from '@angular/router';
import { HistorialLecturas } from './pages/admin/historial-lecturas/historial-lecturas';
import { Login } from './pages/login/login';

import { AdminLayout } from './layout/admin-layout/admin-layout';
import { ClienteLayout } from './layout/cliente-layout/cliente-layout';

import { Dashboard } from './pages/admin/dashboard/dashboard';
import { Clientes } from './pages/admin/clientes/clientes';
import { Recibos } from './pages/admin/recibos/recibos';
import { Pagos } from './pages/admin/pagos/pagos';
import { Reportes } from './pages/admin/reportes/reportes';
import { Tarifas } from './pages/admin/tarifas/tarifas';
import { QrSuministro } from './pages/admin/qr-suministro/qr-suministro';
import { Lecturadores } from './pages/admin/lecturadores/lecturadores';

import { Inicio } from './pages/cliente/inicio/inicio';
import { MisSuministros } from './pages/cliente/mis-suministros/mis-suministros';
import { DetalleSuministro } from './pages/cliente/detalle-suministro/detalle-suministro';
import { MisRecibos } from './pages/cliente/mis-recibos/mis-recibos';
import { DetalleRecibo } from './pages/cliente/detalle-recibo/detalle-recibo';
import { PagarRecibo } from './pages/cliente/pagar-recibo/pagar-recibo';
import { Perfil } from './pages/cliente/perfil/perfil';
import { Contrasena } from './pages/cliente/contrasena/contrasena';

import { LecturasLecturador } from './pages/lecturador/lecturas/lecturas';

import { authGuard } from './core/guards/auth-guard';
import { roleGuard } from './core/guards/role-guard';

import { Sectores } from './pages/admin/sectores/sectores';

import { SinLecturas } from './pages/admin/sin-lecturas/sin-lecturas';
import { CanalesPago } from './pages/admin/canales-pago/canales-pago';
import { Caja } from './pages/admin/caja/caja';

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
      { path: 'lecturadores', component: Lecturadores },
      { path: 'recibos', component: Recibos },
      { path: 'pagos', component: Pagos },
      { path: 'canales-pago', component: CanalesPago },
      { path: 'reportes', component: Reportes },
      { path: 'tarifas', component: Tarifas },
      { path: 'qr-suministro', component: QrSuministro },
      { path: 'historial-lecturas', component: HistorialLecturas },
      { path: 'sectores', component: Sectores },
      { path: 'caja', component: Caja },
      { path: 'sin-lecturas', component: SinLecturas }
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
      { path: 'mis-suministros', component: MisSuministros },
      { path: 'detalle-suministro/:codigo', component: DetalleSuministro },
      { path: 'mis-recibos', component: MisRecibos },
      { path: 'detalle-recibo/:id', component: DetalleRecibo },
      { path: 'pagar-recibo/:id', component: PagarRecibo },
      { path: 'perfil', component: Perfil },
      { path: 'contrasena', component: Contrasena },
      { path: 'cambiar-password', redirectTo: 'contrasena', pathMatch: 'full' }
    ]
  },
  {
    path: 'lecturador',
    canActivate: [authGuard, roleGuard],
    data: { roles: ['LECTURADOR'] },
    children: [
      { path: '', redirectTo: 'lecturas', pathMatch: 'full' },
      { path: 'lecturas', component: LecturasLecturador }
    ]
  },
  {
    path: '**',
    redirectTo: 'login'
  },
  
];