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
  selector: 'app-perfil',
  imports: [CommonModule, RouterModule],
  templateUrl: './perfil.html',
  styleUrl: './perfil.scss',
})
export class Perfil implements OnInit {
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
    this.cargarPerfil();
  }

  cargarPerfil(): void {
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
          this.guardarDatosUsuario();
          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudo cargar la información de tu perfil.';
          this.perfil = null;
          this.suministros = [];
          this.recibos = [];
          this.cdr.detectChanges();
        }
      });
  }

  guardarDatosUsuario(): void {
    const nombre = this.nombreCompleto();

    if (nombre && nombre !== 'Cliente') {
      localStorage.setItem('nombreUsuario', nombre);
    }

    if (this.codigoUsuario() && this.codigoUsuario() !== '-') {
      localStorage.setItem('codigoUsuario', this.codigoUsuario());
    }
  }

  nombreCompleto(): string {
    const item: any = this.perfil || {};

    const nombres = item.nombres || '';
    const apellidos = item.apellidos || '';

    return `${nombres} ${apellidos}`.trim() ||
      localStorage.getItem('nombreUsuario') ||
      'Cliente';
  }

  primerNombre(): string {
    return this.nombreCompleto().split(' ')[0] || 'Cliente';
  }

  iniciales(): string {
    const nombre = this.nombreCompleto();
    const partes = nombre.split(' ').filter(Boolean);

    if (partes.length >= 2) {
      return `${partes[0][0]}${partes[1][0]}`.toUpperCase();
    }

    return nombre.substring(0, 1).toUpperCase();
  }

  valorPerfil(campo: string): string {
    const item: any = this.perfil || {};
    return item[campo] || '-';
  }

  codigoUsuario(): string {
    const item: any = this.perfil || {};
    return item.codigoUsuario ||
      item.usuario ||
      localStorage.getItem('codigoUsuario') ||
      '-';
  }

  dniCliente(): string {
    const item: any = this.perfil || {};
    return item.dni || item.documento || item.numeroDocumento || '-';
  }

  telefonoCliente(): string {
    const item: any = this.perfil || {};
    return item.telefono || item.celular || '-';
  }

  correoCliente(): string {
    const item: any = this.perfil || {};
    return item.correo || item.email || '-';
  }

  estadoCliente(): string {
    const item: any = this.perfil || {};

    if (item.estado === false || String(item.estado || '').toUpperCase() === 'INACTIVO') {
      return 'Inactivo';
    }

    return 'Activo';
  }

  estadoClienteClase(): string {
    return this.estadoCliente().toLowerCase() === 'activo' ? 'pagado' : 'vencido';
  }

  direccionPrincipal(): string {
    const principal = this.suministros.length ? this.suministros[0] : null;

    if (!principal) {
      return '-';
    }

    const item: any = principal;
    return item.direccionSuministro || item.direccion || '-';
  }

  totalSuministros(): number {
    return this.suministros.length;
  }

  suministrosActivos(): number {
    return this.suministros.filter((item) => this.estadoSuministro(item) === 'ACTIVO').length;
  }

  suministrosPendientes(): number {
    return this.suministros.filter((item) => this.estadoSuministro(item) === 'PENDIENTE').length;
  }

  suministrosSuspendidos(): number {
    return this.suministros.filter((item) => this.estadoSuministro(item) === 'SUSPENDIDO').length;
  }

  recibosPendientes(): number {
    return this.recibos.filter((recibo) => {
      return String(recibo.estadoRecibo || '').toUpperCase() !== 'PAGADO';
    }).length;
  }

  deudaTotal(): number {
    return this.recibos
      .filter((recibo) => String(recibo.estadoRecibo || '').toUpperCase() !== 'PAGADO')
      .reduce((total, recibo) => total + Number(recibo.total || 0), 0);
  }

  totalPagado(): number {
    return this.recibos
      .filter((recibo) => String(recibo.estadoRecibo || '').toUpperCase() === 'PAGADO')
      .reduce((total, recibo) => total + Number(recibo.total || 0), 0);
  }

  private normalizarTexto(value: any): string {
    return String(value ?? '')
      .trim()
      .toUpperCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/_/g, ' ')
      .replace(/-/g, ' ');
  }

  private textoEstadoSuministro(suministro: SuministroClienteResponse): string {
    const item: any = suministro || {};

    return [
      item.estado,
      item.estadoSuministro,
      item.estadoInstalacion,
      item.estadoConexion,
      item.mensajeEstado,
      item.descripcionEstado,
      item.estadoServicio,
      item.situacion
    ]
      .map((value) => this.normalizarTexto(value))
      .filter(Boolean)
      .join(' ');
  }

  estadoSuministro(suministro: SuministroClienteResponse): 'ACTIVO' | 'PENDIENTE' | 'SUSPENDIDO' {
    const item: any = suministro || {};
    const texto = this.textoEstadoSuministro(suministro);

    const esPendiente =
      texto.includes('PENDIENTE') ||
      texto.includes('POR INSTALAR') ||
      texto.includes('NO INSTALADO') ||
      texto.includes('SIN INSTALAR') ||
      texto.includes('INSTALACION PENDIENTE');

    const esSuspendido =
      texto.includes('SUSPENDIDO') ||
      texto.includes('SUSPENDIDA') ||
      texto.includes('SUSPEND') ||
      texto.includes('CORTE') ||
      texto.includes('CORTADO') ||
      texto.includes('INACTIVO') ||
      texto.includes('BAJA');

    if (esPendiente) {
      return 'PENDIENTE';
    }

    if (esSuspendido) {
      return 'SUSPENDIDO';
    }

    if (item.estado === false) {
      return 'SUSPENDIDO';
    }

    return 'ACTIVO';
  }

  estadoSuministroTexto(suministro: SuministroClienteResponse): string {
    const texto = this.textoEstadoSuministro(suministro);
    const estado = this.estadoSuministro(suministro);

    if (estado === 'ACTIVO') {
      return 'Activo';
    }

    if (estado === 'SUSPENDIDO') {
      return 'Suspendido';
    }

    if (texto.includes('SUSPEND')) {
      return 'Pendiente / suspendido';
    }

    return 'Pendiente';
  }

  estadoSuministroClase(suministro: SuministroClienteResponse): string {
    const estado = this.estadoSuministro(suministro);

    if (estado === 'ACTIVO') {
      return 'pagado';
    }

    if (estado === 'SUSPENDIDO') {
      return 'vencido';
    }

    return 'pendiente';
  }

  suministroValor(suministro: SuministroClienteResponse, campo: string): string {
    const item: any = suministro || {};
    return item[campo] || '-';
  }

  direccionSuministro(suministro: SuministroClienteResponse): string {
    const item: any = suministro || {};
    return item.direccionSuministro || item.direccion || '-';
  }

  sectorSuministro(suministro: SuministroClienteResponse): string {
    const item: any = suministro || {};
    return item.nombreSector || item.sector || '-';
  }
}
