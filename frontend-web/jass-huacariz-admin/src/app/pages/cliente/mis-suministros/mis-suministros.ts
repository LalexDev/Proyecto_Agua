import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { RouterModule } from '@angular/router';
import { catchError, finalize, forkJoin, of } from 'rxjs';

import {
  ClientePerfilResponse,
  ClientePortal,
  ReciboClienteResponse,
  SuministroClienteResponse
} from '../../../core/services/cliente-portal';

@Component({
  selector: 'app-mis-suministros',
  imports: [CommonModule, RouterModule],
  templateUrl: './mis-suministros.html',
  styleUrl: './mis-suministros.scss',
})
export class MisSuministros implements OnInit {
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
          this.recibos = recibos || [];
          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudieron cargar tus suministros.';
          this.suministros = [];
          this.recibos = [];
          this.cdr.detectChanges();
        }
      });
  }

  nombreCliente(): string {
    const item: any = this.perfil || {};
    return `${item.nombres || ''} ${item.apellidos || ''}`.trim() || 'Cliente';
  }

  recibosPorSuministro(suministro: SuministroClienteResponse): ReciboClienteResponse[] {
    const codigo = String(suministro.codigoSuministro || '').toUpperCase();

    return this.recibos.filter((recibo: any) => {
      return String(recibo.codigoSuministro || '').toUpperCase() === codigo;
    });
  }

  recibosPendientes(suministro: SuministroClienteResponse): number {
    return this.recibosPorSuministro(suministro).filter((recibo: any) => {
      return String(recibo.estadoRecibo || '').toUpperCase() === 'PENDIENTE';
    }).length;
  }

  totalPendiente(suministro: SuministroClienteResponse): number {
    return this.recibosPorSuministro(suministro)
      .filter((recibo: any) => String(recibo.estadoRecibo || '').toUpperCase() !== 'PAGADO')
      .reduce((total, recibo: any) => total + Number(recibo.total || 0), 0);
  }

  ultimoConsumo(suministro: SuministroClienteResponse): number {
    const recibos = this.recibosPorSuministro(suministro)
      .sort((a: any, b: any) => {
        const periodoA = Number(a.anio || 0) * 100 + Number(a.mes || 0);
        const periodoB = Number(b.anio || 0) * 100 + Number(b.mes || 0);
        return periodoB - periodoA;
      });

    return recibos.length ? Number(recibos[0].consumoM3 || 0) : 0;
  }

  estadoTexto(suministro: SuministroClienteResponse): string {
    const item: any = suministro;

    if (item.estado === false || String(item.estado || '').toUpperCase() === 'SUSPENDIDO') {
      return 'Suspendido';
    }

    const instalacion = String(item.estadoInstalacion || '').toUpperCase();

    if (instalacion === 'PENDIENTE_INSTALACION') {
      return 'Pendiente de instalación';
    }

    return 'Instalado';
  }

  estadoClase(suministro: SuministroClienteResponse): string {
    const texto = this.estadoTexto(suministro).toLowerCase();

    if (texto.includes('pendiente')) {
      return 'pendiente';
    }

    if (texto.includes('suspendido')) {
      return 'suspendido';
    }

    return 'instalado';
  }

  valor(suministro: SuministroClienteResponse, campo: string): string {
    const item: any = suministro || {};
    return item[campo] || '-';
  }
  recibosPendientesTotal(): number {
  return this.recibos
    .filter((recibo: any) => String(recibo.estadoRecibo || '').toUpperCase() !== 'PAGADO')
    .reduce((total, recibo: any) => total + Number(recibo.total || 0), 0);
  }

}