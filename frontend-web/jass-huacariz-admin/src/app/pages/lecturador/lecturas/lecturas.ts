import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { finalize } from 'rxjs';

import {
  LecturaRequest,
  LecturaResponse,
  Lecturador,
  SuministroLecturadorResponse
} from '../../../core/services/lecturador';

@Component({
  selector: 'app-lecturas-lecturador',
  imports: [CommonModule, FormsModule],
  templateUrl: './lecturas.html',
  styleUrl: './lecturas.scss',
})
export class LecturasLecturador {
  codigoBusqueda = '';

  suministro: SuministroLecturadorResponse | null = null;
  lecturaGenerada: LecturaResponse | null = null;

  cargando = false;
  registrando = false;
  error = '';
  exito = '';

  lecturaForm: LecturaRequest = this.crearLecturaVacia();

  constructor(
    private lecturadorService: Lecturador,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  buscarSuministro(): void {
    this.error = '';
    this.exito = '';
    this.lecturaGenerada = null;
    this.suministro = null;

    const codigo = this.codigoBusqueda.trim().toUpperCase();

    if (!codigo) {
      this.error = 'Ingrese o escanee el código del suministro.';
      return;
    }

    this.cargando = true;

    this.lecturadorService.buscarSuministro(codigo)
      .pipe(
        finalize(() => {
          this.cargando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (data) => {
          this.suministro = data;
          this.lecturaForm = {
            codigoSuministro: data.codigoSuministro,
            anio: new Date().getFullYear(),
            mes: new Date().getMonth() + 1,
            lecturaActual: 0,
            observacion: 'Lectura mensual registrada'
          };
          this.cdr.detectChanges();
        },
        error: (err) => {
          this.error = err?.error?.error || 'No se encontró el suministro.';
          this.cdr.detectChanges();
        }
      });
  }

  registrarLectura(): void {
    this.error = '';
    this.exito = '';
    this.lecturaGenerada = null;

    if (!this.suministro) {
      this.error = 'Primero busque un suministro.';
      return;
    }

    if (!this.lecturaForm.anio || this.lecturaForm.anio < 2024) {
      this.error = 'Ingrese un año válido.';
      return;
    }

    if (!this.lecturaForm.mes || this.lecturaForm.mes < 1 || this.lecturaForm.mes > 12) {
      this.error = 'Ingrese un mes válido entre 1 y 12.';
      return;
    }

    if (!this.lecturaForm.lecturaActual || this.lecturaForm.lecturaActual <= 0) {
      this.error = 'Ingrese la lectura actual.';
      return;
    }

    if (Number(this.lecturaForm.lecturaActual) < Number(this.suministro.lecturaInicial)) {
      this.error = 'La lectura actual no puede ser menor a la lectura inicial/anterior.';
      return;
    }

    this.registrando = true;

    const payload: LecturaRequest = {
      codigoSuministro: this.suministro.codigoSuministro,
      anio: Number(this.lecturaForm.anio),
      mes: Number(this.lecturaForm.mes),
      lecturaActual: Number(this.lecturaForm.lecturaActual),
      observacion: this.lecturaForm.observacion?.trim() || 'Lectura mensual registrada'
    };

    this.lecturadorService.registrarLectura(payload)
      .pipe(
        finalize(() => {
          this.registrando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (data) => {
          this.lecturaGenerada = data;
          this.exito = 'Lectura registrada y recibo generado correctamente.';
          this.cdr.detectChanges();
        },
        error: (err) => {
          this.error = err?.error?.error || 'No se pudo registrar la lectura.';
          this.cdr.detectChanges();
        }
      });
  }

  limpiar(): void {
    this.codigoBusqueda = '';
    this.suministro = null;
    this.lecturaGenerada = null;
    this.error = '';
    this.exito = '';
    this.lecturaForm = this.crearLecturaVacia();
  }

  cerrarSesion(): void {
    localStorage.clear();
    sessionStorage.clear();
    this.router.navigate(['/login']);
  }

  nombreMes(mes: number): string {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return meses[mes - 1] ?? 'Mes inválido';
  }

  private crearLecturaVacia(): LecturaRequest {
    return {
      codigoSuministro: '',
      anio: new Date().getFullYear(),
      mes: new Date().getMonth() + 1,
      lecturaActual: 0,
      observacion: 'Lectura mensual registrada'
    };
  }
}