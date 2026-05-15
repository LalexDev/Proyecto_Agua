import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { finalize } from 'rxjs';

import { Tarifa, TarifaRequest, TarifaResponse } from '../../../core/services/tarifa';

@Component({
  selector: 'app-tarifas',
  imports: [CommonModule, FormsModule],
  templateUrl: './tarifas.html',
  styleUrl: './tarifas.scss',
})
export class Tarifas implements OnInit {
  tarifas: TarifaResponse[] = [];

  cargando = false;
  guardando = false;
  error = '';
  exito = '';

  mostrarFormulario = false;

  nuevaTarifa: TarifaRequest = this.crearTarifaVacia();

  constructor(
    private tarifaService: Tarifa,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarTarifas();
  }

  cargarTarifas(): void {
    this.cargando = true;
    this.error = '';
    this.exito = '';

    this.tarifaService.listarTarifas()
      .pipe(
        finalize(() => {
          this.cargando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (data) => {
          this.tarifas = data;
          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudieron cargar las tarifas. Verifica el backend y tu sesión ADMIN.';
          this.cdr.detectChanges();
        }
      });
  }

  abrirFormulario(): void {
    this.mostrarFormulario = true;
    this.error = '';
    this.exito = '';
    this.nuevaTarifa = this.crearTarifaVacia();
  }

  cerrarFormulario(): void {
    this.mostrarFormulario = false;
    this.error = '';
    this.exito = '';
  }

  registrarTarifa(): void {
    this.error = '';
    this.exito = '';

    if (!this.validarFormulario()) {
      return;
    }

    this.guardando = true;

    const payload: TarifaRequest = {
      nombreTarifa: this.nuevaTarifa.nombreTarifa.trim(),
      consumoDesde: Number(this.nuevaTarifa.consumoDesde),
      consumoHasta: this.nuevaTarifa.consumoHasta === null || this.nuevaTarifa.consumoHasta === undefined
        ? null
        : Number(this.nuevaTarifa.consumoHasta),
      precioM3: Number(this.nuevaTarifa.precioM3),
      estado: this.nuevaTarifa.estado
    };

    this.tarifaService.registrarTarifa(payload)
      .pipe(
        finalize(() => {
          this.guardando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: () => {
          this.exito = 'Tarifa registrada correctamente.';
          this.mostrarFormulario = false;
          this.cargarTarifas();
        },
        error: (err) => {
          this.error = err?.error?.error || 'No se pudo registrar la tarifa.';
          this.cdr.detectChanges();
        }
      });
  }

  estadoTexto(estado: boolean): string {
    return estado ? 'Activa' : 'Inactiva';
  }

  rangoConsumo(tarifa: TarifaResponse): string {
    if (tarifa.consumoHasta === null || tarifa.consumoHasta === undefined) {
      return `${tarifa.consumoDesde} m³ a más`;
    }

    return `${tarifa.consumoDesde} m³ - ${tarifa.consumoHasta} m³`;
  }

  totalActivas(): number {
    return this.tarifas.filter(t => t.estado).length;
  }

  precioPromedio(): number {
    if (this.tarifas.length === 0) {
      return 0;
    }

    const total = this.tarifas.reduce((suma, tarifa) => suma + Number(tarifa.precioM3), 0);
    return total / this.tarifas.length;
  }

  private validarFormulario(): boolean {
    if (!this.nuevaTarifa.nombreTarifa.trim()) {
      this.error = 'Ingrese el nombre de la tarifa.';
      return false;
    }

    if (this.nuevaTarifa.consumoDesde < 0) {
      this.error = 'El consumo desde no puede ser negativo.';
      return false;
    }

    if (this.nuevaTarifa.consumoHasta !== null && this.nuevaTarifa.consumoHasta < this.nuevaTarifa.consumoDesde) {
      this.error = 'El consumo hasta no puede ser menor al consumo desde.';
      return false;
    }

    if (this.nuevaTarifa.precioM3 <= 0) {
      this.error = 'El precio por m³ debe ser mayor a 0.';
      return false;
    }

    return true;
  }

  private crearTarifaVacia(): TarifaRequest {
    return {
      nombreTarifa: '',
      consumoDesde: 0,
      consumoHasta: null,
      precioM3: 0,
      estado: true
    };
  }
}