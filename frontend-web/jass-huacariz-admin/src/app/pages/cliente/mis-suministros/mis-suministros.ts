import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { finalize, forkJoin } from 'rxjs';

import {
  ClientePerfilResponse,
  ClientePortal,
  ReciboClienteResponse,
  SuministroClienteResponse
} from '../../../core/services/cliente-portal';

@Component({
  selector: 'app-mis-suministros',
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './mis-suministros.html',
  styleUrl: './mis-suministros.scss',
})
export class MisSuministros implements OnInit {
  perfil: ClientePerfilResponse | null = null;
  suministros: SuministroClienteResponse[] = [];
  suministrosFiltrados: SuministroClienteResponse[] = [];
  recibos: ReciboClienteResponse[] = [];

  cargando = false;
  error = '';

  busqueda = '';
  filtroEstado = 'TODOS';

  constructor(
    private clientePortal: ClientePortal,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarSuministros();
  }

  cargarDatos(): void {
    this.cargarSuministros();
  }

  cargarSuministros(): void {
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
          this.aplicarFiltros();
          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudieron cargar tus suministros.';
          this.perfil = null;
          this.suministros = [];
          this.suministrosFiltrados = [];
          this.recibos = [];
          this.cdr.detectChanges();
        }
      });
  }

  aplicarFiltros(): void {
    const texto = this.busqueda.trim().toLowerCase();

    this.suministrosFiltrados = this.suministros.filter((suministro: any) => {
      const estado = this.estadoSuministro(suministro);

      const coincideEstado =
        this.filtroEstado === 'TODOS' ||
        this.filtroEstado === '' ||
        estado === this.filtroEstado;

      const coincideTexto =
        !texto ||
        String(suministro.codigoSuministro || '').toLowerCase().includes(texto) ||
        String(suministro.aliasSuministro || '').toLowerCase().includes(texto) ||
        String(suministro.direccionSuministro || '').toLowerCase().includes(texto) ||
        String(suministro.direccion || '').toLowerCase().includes(texto) ||
        String(suministro.nombreSector || '').toLowerCase().includes(texto) ||
        String(suministro.sector || '').toLowerCase().includes(texto) ||
        String(suministro.referencia || '').toLowerCase().includes(texto) ||
        this.estadoTexto(suministro).toLowerCase().includes(texto);

      return coincideEstado && coincideTexto;
    });
  }

  limpiarFiltros(): void {
    this.busqueda = '';
    this.filtroEstado = 'TODOS';
    this.aplicarFiltros();
  }

  nombreCliente(): string {
    const item: any = this.perfil || {};

    return `${item.nombres || ''} ${item.apellidos || ''}`.trim() ||
      localStorage.getItem('nombreUsuario') ||
      'Cliente';
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

  porcentajeActivos(): number {
    if (!this.totalSuministros()) {
      return 0;
    }

    return (this.suministrosActivos() / this.totalSuministros()) * 100;
  }

  porcentajePendientes(): number {
    if (!this.totalSuministros()) {
      return 0;
    }

    return (this.suministrosPendientes() / this.totalSuministros()) * 100;
  }

  porcentajeSuspendidos(): number {
    if (!this.totalSuministros()) {
      return 0;
    }

    return (this.suministrosSuspendidos() / this.totalSuministros()) * 100;
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

  estadoTexto(suministro: SuministroClienteResponse): string {
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

  estadoClase(suministro: SuministroClienteResponse): string {
    const estado = this.estadoSuministro(suministro);

    if (estado === 'ACTIVO') {
      return 'pagado';
    }

    if (estado === 'SUSPENDIDO') {
      return 'vencido';
    }

    return 'pendiente';
  }

  codigoSuministro(suministro: SuministroClienteResponse): string {
    const item: any = suministro || {};
    return item.codigoSuministro || '-';
  }

  alias(suministro: SuministroClienteResponse): string {
    return this.aliasSuministro(suministro);
  }

  aliasSuministro(suministro: SuministroClienteResponse): string {
    const item: any = suministro || {};
    return item.aliasSuministro || 'Suministro de agua';
  }

  direccion(suministro: SuministroClienteResponse): string {
    return this.direccionSuministro(suministro);
  }

  direccionSuministro(suministro: SuministroClienteResponse): string {
    const item: any = suministro || {};
    return item.direccionSuministro || item.direccion || '-';
  }

  sector(suministro: SuministroClienteResponse): string {
    return this.sectorSuministro(suministro);
  }

  sectorSuministro(suministro: SuministroClienteResponse): string {
    const item: any = suministro || {};
    return item.nombreSector || item.sector || '-';
  }

  referenciaSuministro(suministro: SuministroClienteResponse): string {
    const item: any = suministro || {};
    return item.referencia || '-';
  }

  private codigoDesdeInput(input: SuministroClienteResponse | string): string {
    if (typeof input === 'string') {
      return input.toUpperCase();
    }

    return this.codigoSuministro(input).toUpperCase();
  }

  recibosPorSuministro(input: SuministroClienteResponse | string): ReciboClienteResponse[] {
    const codigo = this.codigoDesdeInput(input);

    return this.recibos.filter((recibo) => {
      return String(recibo.codigoSuministro || '').toUpperCase() === codigo;
    });
  }

  ultimoRecibo(input: SuministroClienteResponse | string): ReciboClienteResponse | null {
    const lista = [...this.recibosPorSuministro(input)]
      .sort((a, b) => Number(b.id) - Number(a.id));

    return lista.length ? lista[0] : null;
  }

  deudaSuministro(input: SuministroClienteResponse | string): number {
    return this.recibosPorSuministro(input)
      .filter((recibo) => String(recibo.estadoRecibo || '').toUpperCase() !== 'PAGADO')
      .reduce((total, recibo) => total + Number(recibo.total || 0), 0);
  }

  deudaPorSuministro(input: SuministroClienteResponse | string): number {
    return this.deudaSuministro(input);
  }

  ultimoConsumo(input: SuministroClienteResponse | string): number {
    const recibo = this.ultimoRecibo(input);
    return Number(recibo?.consumoM3 || 0);
  }

  periodo(recibo: ReciboClienteResponse): string {
    return `${this.nombreMes(Number(recibo.mes))} ${recibo.anio}`;
  }

  nombreMes(mes: number): string {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return meses[mes - 1] || 'Mes inválido';
  }
}