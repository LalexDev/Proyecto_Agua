import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { finalize } from 'rxjs';

import {
  HistorialLectura,
  LecturaAdmin
} from '../../../core/services/lectura-admin';

@Component({
  selector: 'app-historial-lecturas',
  imports: [CommonModule, FormsModule],
  templateUrl: './historial-lecturas.html',
  styleUrl: './historial-lecturas.scss',
})
export class HistorialLecturas implements OnInit {
  lecturas: HistorialLectura[] = [];
  lecturasFiltradas: HistorialLectura[] = [];

  busqueda = '';
  filtroAnio: number | '' = '';
  filtroMes: number | '' = '';

  cargando = false;
  error = '';

  constructor(
    private lecturaAdmin: LecturaAdmin,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarHistorial();
  }

  cargarHistorial(): void {
    this.cargando = true;
    this.error = '';

    this.lecturaAdmin.listarHistorial()
      .pipe(
        finalize(() => {
          this.cargando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (data) => {
          this.lecturas = data || [];
          this.aplicarFiltros();
          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudo cargar el historial de lecturas.';
          this.lecturas = [];
          this.lecturasFiltradas = [];
          this.cdr.detectChanges();
        }
      });
  }

  aplicarFiltros(): void {
    const texto = this.busqueda.trim().toLowerCase();

    this.lecturasFiltradas = this.lecturas.filter((item) => {
      const coincideTexto =
        !texto ||
        String(item.codigoSuministro || '').toLowerCase().includes(texto) ||
        String(item.aliasSuministro || '').toLowerCase().includes(texto) ||
        String(item.direccionSuministro || '').toLowerCase().includes(texto) ||
        String(item.cliente || '').toLowerCase().includes(texto) ||
        String(item.dniCliente || '').toLowerCase().includes(texto) ||
        String(item.codigoRecibo || '').toLowerCase().includes(texto) ||
        String(item.sector || '').toLowerCase().includes(texto);

      const coincideAnio =
        !this.filtroAnio || Number(item.anio) === Number(this.filtroAnio);

      const coincideMes =
        !this.filtroMes || Number(item.mes) === Number(this.filtroMes);

      return coincideTexto && coincideAnio && coincideMes;
    });
  }

  limpiarFiltros(): void {
    this.busqueda = '';
    this.filtroAnio = '';
    this.filtroMes = '';
    this.aplicarFiltros();
  }

  nombreMes(mes: number): string {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return meses[mes - 1] || 'Mes inválido';
  }

  totalConsumo(): number {
    return this.lecturasFiltradas.reduce((total, item) => {
      return total + Number(item.consumoM3 || 0);
    }, 0);
  }

  totalEmitido(): number {
    return this.lecturasFiltradas.reduce((total, item) => {
      return total + Number(item.totalRecibo || 0);
    }, 0);
  }

  totalPendientes(): number {
    return this.lecturasFiltradas.filter((item) => {
      return String(item.estadoRecibo || '').toUpperCase() === 'PENDIENTE';
    }).length;
  }

  totalPagados(): number {
    return this.lecturasFiltradas.filter((item) => {
      return String(item.estadoRecibo || '').toUpperCase() === 'PAGADO';
    }).length;
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
}