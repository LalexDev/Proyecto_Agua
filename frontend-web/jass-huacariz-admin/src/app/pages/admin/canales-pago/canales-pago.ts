import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';

import {
  CanalPago,
  CanalPagoResponse
} from '../../../core/services/canal-pago';

@Component({
  selector: 'app-canales-pago',
  imports: [CommonModule, FormsModule],
  templateUrl: './canales-pago.html',
  styleUrl: './canales-pago.scss',
})
export class CanalesPago implements OnInit {
  canales: CanalPagoResponse[] = [];
  canalEditando: CanalPagoResponse | null = null;

  cargando = false;
  guardando = false;
  error = '';
  exito = '';

  constructor(
    private canalPagoService: CanalPago,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarCanales();
  }

  cargarCanales(): void {
    this.cargando = true;
    this.error = '';
    this.exito = '';

    this.canalPagoService.listarTodos().subscribe({
      next: (data) => {
        this.canales = data || [];
        this.cargando = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.error = 'No se pudieron cargar los canales de pago.';
        this.canales = [];
        this.cargando = false;
        this.cdr.detectChanges();
      }
    });
  }

  editar(canal: CanalPagoResponse): void {
    this.canalEditando = { ...canal };
    this.error = '';
    this.exito = '';
  }

  cerrarEditor(): void {
    this.canalEditando = null;
  }

  guardar(): void {
    if (!this.canalEditando) {
      return;
    }

    if (!this.canalEditando.titular?.trim()) {
      this.error = 'El titular es obligatorio.';
      return;
    }

    this.guardando = true;
    this.error = '';
    this.exito = '';

    this.canalPagoService.actualizar(this.canalEditando.id, this.canalEditando).subscribe({
      next: () => {
        this.exito = 'Canal de pago actualizado correctamente.';
        this.guardando = false;
        this.canalEditando = null;
        this.cargarCanales();
        this.cdr.detectChanges();
      },
      error: () => {
        this.error = 'No se pudo actualizar el canal de pago.';
        this.guardando = false;
        this.cdr.detectChanges();
      }
    });
  }

  estadoTexto(canal: CanalPagoResponse): string {
    return canal.estado ? 'Activo' : 'Inactivo';
  }

  estadoClase(canal: CanalPagoResponse): string {
    return canal.estado ? 'activo' : 'inactivo';
  }

  normalizarMetodo(metodo: string): string {
    const valor = String(metodo || '').toUpperCase();

    if (valor === 'YAPE') return 'Yape';
    if (valor === 'PLIN') return 'Plin';
    if (valor === 'TRANSFERENCIA') return 'Transferencia';

    return metodo || 'Sin método';
  }
}