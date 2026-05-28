import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { ActivatedRoute, RouterModule } from '@angular/router';
import { catchError, finalize, forkJoin, of } from 'rxjs';

import {
  ClientePerfilResponse,
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

  perfil: ClientePerfilResponse | null = null;
  suministro: SuministroClienteResponse | null = null;
  suministros: SuministroClienteResponse[] = [];
  recibos: ReciboClienteResponse[] = [];

  cargando = false;
  error = '';

  constructor(
    private route: ActivatedRoute,
    private clientePortal: ClientePortal,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.codigoSuministro = String(this.route.snapshot.paramMap.get('codigo') || '').trim();
    this.cargarDatos();
  }

  cargarDatos(): void {
    this.cargando = true;
    this.error = '';

    forkJoin({
      perfil: this.clientePortal.obtenerMiPerfil().pipe(catchError(() => of(null))),
      suministros: this.clientePortal.listarMisSuministros(),
      recibos: this.clientePortal.listarMisRecibos().pipe(catchError(() => of([])))
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
          this.recibos = (recibos || []).filter((recibo: any) => {
            return String(recibo.codigoSuministro || '').toUpperCase() === this.codigoSuministro.toUpperCase();
          });

          this.suministro = this.suministros.find((item: any) => {
            return String(item.codigoSuministro || '').toUpperCase() === this.codigoSuministro.toUpperCase();
          }) || null;

          if (!this.suministro) {
            this.error = 'No se encontró el suministro seleccionado.';
          }

          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudo cargar el detalle del suministro.';
          this.suministro = null;
          this.recibos = [];
          this.cdr.detectChanges();
        }
      });
  }

  imprimirRecibo(recibo: ReciboClienteResponse): void {
    const reciboCompleto: any = {
      ...recibo,
      nombreCliente: recibo.nombreCliente || this.nombreCliente(),
      dniCliente: recibo.dniCliente || this.dniCliente(),
      direccionSuministro: recibo.direccionSuministro || this.valor('direccionSuministro'),
      aliasSuministro: recibo.aliasSuministro || this.valor('aliasSuministro'),
      sector: recibo.sector || this.valor('nombreSector'),
      codigoBarras: recibo.codigoBarras || `${recibo.codigoRecibo || ''}-${recibo.codigoSuministro || ''}`
    };

    imprimirReciboJass(reciboCompleto, this.recibos);
  }

  nombreCliente(): string {
    const item: any = this.perfil || {};
    return `${item.nombres || ''} ${item.apellidos || ''}`.trim() || 'Cliente';
  }

  dniCliente(): string {
    const item: any = this.perfil || {};
    return item.dni || '-';
  }

  valor(campo: string): string {
    const item: any = this.suministro || {};
    return item[campo] || '-';
  }

  estadoTexto(): string {
    const item: any = this.suministro || {};

    if (item.estado === false || String(item.estado || '').toUpperCase() === 'SUSPENDIDO') {
      return 'Suspendido';
    }

    const instalacion = String(item.estadoInstalacion || '').toUpperCase();

    if (instalacion === 'PENDIENTE_INSTALACION') {
      return 'Pendiente de instalación';
    }

    return 'Instalado';
  }

  estadoClase(): string {
    const texto = this.estadoTexto().toLowerCase();

    if (texto.includes('pendiente')) {
      return 'pendiente';
    }

    if (texto.includes('suspendido')) {
      return 'suspendido';
    }

    return 'instalado';
  }

  recibosPendientes(): number {
    return this.recibos.filter((recibo: any) => {
      return String(recibo.estadoRecibo || '').toUpperCase() === 'PENDIENTE';
    }).length;
  }

  recibosPagados(): number {
    return this.recibos.filter((recibo: any) => {
      return String(recibo.estadoRecibo || '').toUpperCase() === 'PAGADO';
    }).length;
  }

  totalPendiente(): number {
    return this.recibos
      .filter((recibo: any) => String(recibo.estadoRecibo || '').toUpperCase() !== 'PAGADO')
      .reduce((total, recibo: any) => total + Number(recibo.total || 0), 0);
  }

  ultimoConsumo(): number {
    if (!this.recibos.length) {
      return 0;
    }

    const ordenados = [...this.recibos].sort((a: any, b: any) => {
      const periodoA = Number(a.anio || 0) * 100 + Number(a.mes || 0);
      const periodoB = Number(b.anio || 0) * 100 + Number(b.mes || 0);
      return periodoB - periodoA;
    });

    return Number(ordenados[0].consumoM3 || 0);
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