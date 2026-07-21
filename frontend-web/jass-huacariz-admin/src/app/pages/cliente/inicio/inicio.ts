import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { RouterModule } from '@angular/router';
import { finalize, forkJoin } from 'rxjs';

import {
  ClientePerfilResponse,
  ClientePortal,
  ReciboClienteResponse,
  SuministroClienteResponse
} from '../../../core/services/cliente-portal';

@Component({
  selector: 'app-inicio',
  imports: [CommonModule, RouterModule],
  templateUrl: './inicio.html',
  styleUrl: './inicio.scss',
})
export class Inicio implements OnInit {
  perfil: ClientePerfilResponse | null = null;
  suministros: SuministroClienteResponse[] = [];
  recibos: ReciboClienteResponse[] = [];

  cargando = false;
  error = '';

  constructor(
    private clientePortal: ClientePortal,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarInicio();
  }

  cargarInicio(): void {
    this.cargando = true;
    this.error = '';

    forkJoin({
      perfil: this.clientePortal.obtenerMiPerfil(),
      suministros: this.clientePortal.listarMisSuministros(),
      recibos: this.clientePortal.listarMisRecibos()
    })
      .pipe(
        finalize(() => {
          this.cargando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: ({ perfil, suministros, recibos }) => {
          this.perfil = perfil;
          this.suministros = suministros || [];
          this.recibos = recibos || [];

          this.actualizarStorageUsuario();

          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudo cargar la informaciÃ³n del cliente.';
          this.perfil = null;
          this.suministros = [];
          this.recibos = [];
          this.cdr.detectChanges();
        }
      });
  }

  actualizarStorageUsuario(): void {
    if (!this.perfil) {
      return;
    }

    const nombre = `${this.perfil.nombres || ''} ${this.perfil.apellidos || ''}`.trim();

    if (nombre) {
      localStorage.setItem('nombreUsuario', nombre);
    }

    if (this.codigoUsuario()) {
      localStorage.setItem('codigoUsuario', this.codigoUsuario());
    }
  }

  nombreCliente(): string {
    if (!this.perfil) {
      return localStorage.getItem('nombreUsuario') || 'Cliente';
    }

    const nombre = `${this.perfil.nombres || ''} ${this.perfil.apellidos || ''}`.trim();
    return nombre || localStorage.getItem('nombreUsuario') || 'Cliente';
  }

  primerNombre(): string {
    return this.nombreCliente().split(' ')[0] || 'Cliente';
  }

  codigoUsuario(): string {
    const item: any = this.perfil || {};
    return item.codigoUsuario || item.usuario || localStorage.getItem('codigoUsuario') || '-';
  }

  dniCliente(): string {
    const item: any = this.perfil || {};
    return item.dni || item.documento || item.numeroDocumento || '-';
  }

  iniciales(): string {
    const nombre = this.nombreCliente();
    const partes = nombre.split(' ').filter(Boolean);

    if (partes.length >= 2) {
      return `${partes[0][0]}${partes[1][0]}`.toUpperCase();
    }

    return nombre.substring(0, 1).toUpperCase();
  }

  recibosPendientes(): number {
    return this.recibos.filter((recibo) => {
      return String(recibo.estadoRecibo || '').toUpperCase() === 'PENDIENTE';
    }).length;
  }

  recibosPagados(): number {
    return this.recibos.filter((recibo) => {
      return String(recibo.estadoRecibo || '').toUpperCase() === 'PAGADO';
    }).length;
  }

  recibosVencidos(): number {
    return this.recibos.filter((recibo) => {
      return String(recibo.estadoRecibo || '').toUpperCase() === 'VENCIDO';
    }).length;
  }

  deudaTotal(): number {
    return this.recibos
      .filter((recibo) => {
        return String(recibo.estadoRecibo || '').toUpperCase() !== 'PAGADO';
      })
      .reduce((total, recibo) => total + Number(recibo.total || 0), 0);
  }

  totalPagado(): number {
    return this.recibos
      .filter((recibo) => {
        return String(recibo.estadoRecibo || '').toUpperCase() === 'PAGADO';
      })
      .reduce((total, recibo) => total + Number(recibo.total || 0), 0);
  }

  consumoTotal(): number {
    return this.recibos.reduce((total, recibo) => {
      return total + Number(recibo.consumoM3 || 0);
    }, 0);
  }

  consumoPromedio(): number {
    if (!this.recibos.length) {
      return 0;
    }

    return this.consumoTotal() / this.recibos.length;
  }

  suministroPrincipal(): SuministroClienteResponse | null {
    return this.suministros.length ? this.suministros[0] : null;
  }

  reciboPendienteMasReciente(): ReciboClienteResponse | null {
    const pendientes = this.recibos
      .filter((recibo) => String(recibo.estadoRecibo || '').toUpperCase() !== 'PAGADO')
      .sort((a, b) => Number(b.id) - Number(a.id));

    return pendientes.length ? pendientes[0] : null;
  }

  ultimosRecibos(): ReciboClienteResponse[] {
    return [...this.recibos]
      .sort((a, b) => Number(b.id) - Number(a.id))
      .slice(0, 5);
  }

  recibosParaGrafico(): ReciboClienteResponse[] {
    return [...this.recibos]
      .sort((a, b) => Number(a.id) - Number(b.id))
      .slice(-6);
  }

  consumoMaximo(): number {
    if (!this.recibosParaGrafico().length) {
      return 0;
    }

    return Math.max(...this.recibosParaGrafico().map((recibo) => Number(recibo.consumoM3 || 0)));
  }

  anchoConsumo(recibo: ReciboClienteResponse): string {
    const maximo = this.consumoMaximo();

    if (maximo <= 0) {
      return '8%';
    }

    const porcentaje = (Number(recibo.consumoM3 || 0) / maximo) * 100;
    return `${Math.max(porcentaje, 8)}%`;
  }

  suministrosActivos(): number {
    return this.suministros.filter((suministro: any) => {
      const estadoInstalacion = String(suministro.estadoInstalacion || '').toUpperCase();

      return suministro.estado !== false &&
        estadoInstalacion !== 'SUSPENDIDO' &&
        estadoInstalacion !== 'PENDIENTE_INSTALACION';
    }).length;
  }

  estadoSuministro(suministro: SuministroClienteResponse): string {
    const item: any = suministro;
    const estadoInstalacion = String(item.estadoInstalacion || '').toUpperCase();

    if (item.estado === false || String(item.estado || '').toUpperCase() === 'SUSPENDIDO') {
      return 'Suspendido';
    }

    if (estadoInstalacion === 'PENDIENTE_INSTALACION') {
      return 'Pendiente';
    }

    if (estadoInstalacion === 'SUSPENDIDO') {
      return 'Suspendido';
    }

    return 'Activo';
  }

  estadoSuministroClase(suministro: SuministroClienteResponse): string {
    const estado = this.estadoSuministro(suministro).toLowerCase();

    if (estado === 'activo') {
      return 'pagado';
    }

    if (estado === 'suspendido') {
      return 'vencido';
    }

    return 'pendiente';
  }

  suministroValor(suministro: SuministroClienteResponse, campo: string): string {
    const item: any = suministro || {};
    return item[campo] || '-';
  }

  porcentajePagados(): number {
    if (!this.recibos.length) {
      return 0;
    }

    return (this.recibosPagados() / this.recibos.length) * 100;
  }

  porcentajePendientes(): number {
    if (!this.recibos.length) {
      return 0;
    }

    return (this.recibosPendientes() / this.recibos.length) * 100;
  }

  porcentajeVencidos(): number {
    if (!this.recibos.length) {
      return 0;
    }

    return (this.recibosVencidos() / this.recibos.length) * 100;
  }

  graficoEstados(): string {
    if (!this.recibos.length) {
      return 'conic-gradient(#e2e8f0 0% 100%)';
    }

    const pagados = this.porcentajePagados();
    const pendientes = this.porcentajePendientes();
    const vencidos = this.porcentajeVencidos();

    const finPagados = pagados;
    const finPendientes = pagados + pendientes;
    const finVencidos = pagados + pendientes + vencidos;

    return `
      conic-gradient(
        #16a34a 0% ${finPagados}%,
        #f59e0b ${finPagados}% ${finPendientes}%,
        #dc2626 ${finPendientes}% ${finVencidos}%,
        #e2e8f0 ${finVencidos}% 100%
      )
    `;
  }

  estadoClase(estado: string): string {
    const valor = String(estado || '').toLowerCase();

    if (valor === 'pagado') {
      return 'pagado';
    }

    if (valor === 'vencido') {
      return 'vencido';
    }

    return 'pendiente';
  }

  periodo(recibo: ReciboClienteResponse): string {
    return `${this.nombreMes(Number(recibo.mes))} ${recibo.anio}`;
  }

  nombreMes(mes: number): string {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return meses[mes - 1] || 'Mes invÃ¡lido';
  }
}
