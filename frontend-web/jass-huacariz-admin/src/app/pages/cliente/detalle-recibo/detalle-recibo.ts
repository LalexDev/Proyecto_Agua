import { CommonModule, Location } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { ActivatedRoute, RouterModule } from '@angular/router';
import { finalize, forkJoin } from 'rxjs';

import {
  ClientePortal,
  ReciboClienteResponse
} from '../../../core/services/cliente-portal';

import { imprimirReciboJass } from '../../../core/utils/recibo-print';

@Component({
  selector: 'app-detalle-recibo',
  imports: [CommonModule, RouterModule],
  templateUrl: './detalle-recibo.html',
  styleUrl: './detalle-recibo.scss',
})
export class DetalleRecibo implements OnInit {
  idRecibo = 0;

  recibo: ReciboClienteResponse | null = null;
  recibos: ReciboClienteResponse[] = [];
  recibosMismoSuministro: ReciboClienteResponse[] = [];

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
      this.idRecibo = Number(params.get('id') || 0);
      this.cargarDetalle();
    });
  }

  cargarDetalle(): void {
    if (!this.idRecibo) {
      this.error = 'No se recibió el ID del recibo.';
      return;
    }

    this.cargando = true;
    this.error = '';

    forkJoin({
      recibo: this.clientePortal.obtenerReciboPorId(this.idRecibo),
      recibos: this.clientePortal.listarMisRecibos()
    })
      .pipe(
        finalize(() => {
          this.cargando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: ({ recibo, recibos }) => {
          this.recibo = recibo;
          this.recibos = recibos || [];

          const codigo = String(recibo.codigoSuministro || '').toUpperCase();

          this.recibosMismoSuministro = this.recibos
            .filter((item) => {
              return String(item.codigoSuministro || '').toUpperCase() === codigo;
            })
            .sort((a, b) => Number(a.id) - Number(b.id));

          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudo cargar el detalle del recibo.';
          this.recibo = null;
          this.recibos = [];
          this.recibosMismoSuministro = [];
          this.cdr.detectChanges();
        }
      });
  }

  volver(): void {
    this.location.back();
  }

  imprimirRecibo(): void {
    if (!this.recibo) {
      return;
    }

    imprimirReciboJass(this.recibo, this.recibosMismoSuministro.length ? this.recibosMismoSuministro : this.recibos);
  }

  puedePagar(): boolean {
    if (!this.recibo) {
      return false;
    }

    return String(this.recibo.estadoRecibo || '').toUpperCase() !== 'PAGADO';
  }

  totalCargos(): number {
    if (!this.recibo) {
      return 0;
    }

    return Number(this.recibo.cargoMantenimiento || 0) +
      Number(this.recibo.cargoLector || 0) +
      Number(this.recibo.cargoOtros || 0) +
      Number(this.recibo.mora || 0);
  }

  codigoBarras(): string {
    if (!this.recibo) {
      return '-';
    }

    return this.recibo.codigoBarras ||
      `${this.recibo.codigoRecibo || ''}-${this.recibo.codigoSuministro || ''}`;
  }

  lineasCodigoBarras(): number[] {
    const codigo = this.codigoBarras();

    if (!codigo || codigo === '-') {
      return [];
    }

    return Array.from(codigo).map((char, index) => {
      const value = char.charCodeAt(0) + index;
      return (value % 4) + 1;
    });
  }

  recibosParaGrafico(): ReciboClienteResponse[] {
    return [...this.recibosMismoSuministro]
      .sort((a, b) => Number(a.id) - Number(b.id))
      .slice(-6);
  }

  consumoMaximo(): number {
    if (!this.recibosParaGrafico().length) {
      return 0;
    }

    return Math.max(...this.recibosParaGrafico().map((item) => Number(item.consumoM3 || 0)));
  }

  anchoConsumo(item: ReciboClienteResponse): string {
    const maximo = this.consumoMaximo();

    if (maximo <= 0) {
      return '8%';
    }

    const porcentaje = (Number(item.consumoM3 || 0) / maximo) * 100;
    return `${Math.max(porcentaje, 8)}%`;
  }

  estadoClase(estado?: string): string {
    const valor = String(estado || '').toLowerCase();

    if (valor === 'pagado') {
      return 'pagado';
    }

    if (valor === 'vencido') {
      return 'vencido';
    }

    return 'pendiente';
  }

  periodo(recibo?: ReciboClienteResponse | null): string {
    if (!recibo) {
      return '-';
    }

    return `${this.nombreMes(Number(recibo.mes))} ${recibo.anio}`;
  }

  nombreMes(mes: number): string {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return meses[mes - 1] || 'Mes inválido';
  }

  fechaCorta(fecha?: string): string {
    if (!fecha) {
      return '-';
    }

    return String(fecha).split('T')[0] || fecha;
  }

  textoSuministro(): string {
    if (!this.recibo) {
      return '-';
    }

    return this.recibo.codigoSuministro || '-';
  }

  textoDireccion(): string {
    if (!this.recibo) {
      return '-';
    }

    return this.recibo.direccionSuministro || '-';
  }

  textoCliente(): string {
    if (!this.recibo) {
      return localStorage.getItem('nombreUsuario') || 'Cliente';
    }

    return this.recibo.nombreCliente ||
      localStorage.getItem('nombreUsuario') ||
      'Cliente';
  }

  textoDni(): string {
    if (!this.recibo) {
      return localStorage.getItem('codigoUsuario') || '-';
    }

    return this.recibo.dniCliente ||
      localStorage.getItem('codigoUsuario') ||
      '-';
  }
}
