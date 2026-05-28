import { CommonModule, Location } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { ActivatedRoute, RouterModule } from '@angular/router';
import { finalize, forkJoin } from 'rxjs';

import {
  ClientePortal,
  ReciboClienteResponse,
  SuministroClienteResponse
} from '../../../core/services/cliente-portal';

import { imprimirReciboJass } from '../../../core/utils/recibo-print';

@Component({
  selector: 'app-detalle-suministro',
  imports: [CommonModule, RouterModule],
  templateUrl: './detalle-suministro.html',
  styleUrl: './detalle-suministro.scss',
})
export class DetalleSuministro implements OnInit {
  codigoSuministro = '';

  suministro: SuministroClienteResponse | null = null;
  recibos: ReciboClienteResponse[] = [];
  recibosSuministro: ReciboClienteResponse[] = [];

  cargando = false;
  error = '';

  constructor(
    private route: ActivatedRoute,
    private location: Location,
    private clientePortal: ClientePortal,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.route.paramMap.subscribe((params) => {
      this.codigoSuministro = params.get('codigo') || '';
      this.cargarDetalle();
    });
  }

  cargarDetalle(): void {
    if (!this.codigoSuministro) {
      this.error = 'No se recibió el código del suministro.';
      return;
    }

    this.cargando = true;
    this.error = '';

    forkJoin({
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
        next: ({ suministros, recibos }) => {
          const codigo = this.codigoSuministro.toUpperCase();

          this.suministro = (suministros || []).find((item) => {
            return String(item.codigoSuministro || '').toUpperCase() === codigo;
          }) || null;

          this.recibos = recibos || [];

          this.recibosSuministro = this.recibos
            .filter((recibo) => {
              return String(recibo.codigoSuministro || '').toUpperCase() === codigo;
            })
            .sort((a, b) => Number(b.id) - Number(a.id));

          if (!this.suministro) {
            this.error = 'No se encontró el suministro solicitado.';
          }

          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudo cargar el detalle del suministro.';
          this.suministro = null;
          this.recibosSuministro = [];
          this.cdr.detectChanges();
        }
      });
  }

  volver(): void {
    this.location.back();
  }

  alias(): string {
    const item: any = this.suministro || {};
    return item.aliasSuministro || 'Suministro de agua';
  }

  direccion(): string {
    const item: any = this.suministro || {};
    return item.direccionSuministro || item.direccion || '-';
  }

  sector(): string {
    const item: any = this.suministro || {};
    return item.nombreSector || item.sector || '-';
  }

  referencia(): string {
    const item: any = this.suministro || {};
    return item.referencia || '-';
  }

  lecturaInicial(): number {
    const item: any = this.suministro || {};
    return Number(item.lecturaInicial || 0);
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

  private textoEstadoSuministro(): string {
    const item: any = this.suministro || {};

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

  estadoSuministro(): 'ACTIVO' | 'PENDIENTE' | 'SUSPENDIDO' {
    const item: any = this.suministro || {};
    const texto = this.textoEstadoSuministro();

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

  estadoTexto(): string {
    const texto = this.textoEstadoSuministro();
    const estado = this.estadoSuministro();

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

  estadoClase(): string {
    const estado = this.estadoSuministro();

    if (estado === 'ACTIVO') {
      return 'pagado';
    }

    if (estado === 'SUSPENDIDO') {
      return 'vencido';
    }

    return 'pendiente';
  }

  recibosPendientes(): number {
    return this.recibosSuministro.filter((recibo) => {
      return String(recibo.estadoRecibo || '').toUpperCase() !== 'PAGADO';
    }).length;
  }

  recibosPagados(): number {
    return this.recibosSuministro.filter((recibo) => {
      return String(recibo.estadoRecibo || '').toUpperCase() === 'PAGADO';
    }).length;
  }

  recibosVencidos(): number {
    return this.recibosSuministro.filter((recibo) => {
      return String(recibo.estadoRecibo || '').toUpperCase() === 'VENCIDO';
    }).length;
  }

  deudaTotal(): number {
    return this.recibosSuministro
      .filter((recibo) => String(recibo.estadoRecibo || '').toUpperCase() !== 'PAGADO')
      .reduce((total, recibo) => total + Number(recibo.total || 0), 0);
  }

  totalPagado(): number {
    return this.recibosSuministro
      .filter((recibo) => String(recibo.estadoRecibo || '').toUpperCase() === 'PAGADO')
      .reduce((total, recibo) => total + Number(recibo.total || 0), 0);
  }

  consumoTotal(): number {
    return this.recibosSuministro.reduce((total, recibo) => {
      return total + Number(recibo.consumoM3 || 0);
    }, 0);
  }

  consumoPromedio(): number {
    if (!this.recibosSuministro.length) {
      return 0;
    }

    return this.consumoTotal() / this.recibosSuministro.length;
  }

  ultimoRecibo(): ReciboClienteResponse | null {
    return this.recibosSuministro.length ? this.recibosSuministro[0] : null;
  }

  recibosParaGrafico(): ReciboClienteResponse[] {
    return [...this.recibosSuministro]
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

  porcentajePagados(): number {
    if (!this.recibosSuministro.length) {
      return 0;
    }

    return (this.recibosPagados() / this.recibosSuministro.length) * 100;
  }

  porcentajePendientes(): number {
    if (!this.recibosSuministro.length) {
      return 0;
    }

    return (this.recibosPendientes() / this.recibosSuministro.length) * 100;
  }

  porcentajeVencidos(): number {
    if (!this.recibosSuministro.length) {
      return 0;
    }

    return (this.recibosVencidos() / this.recibosSuministro.length) * 100;
  }

  graficoEstados(): string {
    if (!this.recibosSuministro.length) {
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

  estadoReciboClase(estado: string): string {
    const valor = String(estado || '').toLowerCase();

    if (valor === 'pagado') {
      return 'pagado';
    }

    if (valor === 'vencido') {
      return 'vencido';
    }

    return 'pendiente';
  }

  puedePagar(recibo: ReciboClienteResponse): boolean {
    return String(recibo.estadoRecibo || '').toUpperCase() !== 'PAGADO';
  }

  imprimirRecibo(recibo: ReciboClienteResponse): void {
    imprimirReciboJass(recibo, this.recibosSuministro);
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