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
      this.qrArchivo = null;
      this.qrPreview = '';
      this.error = '';
      this.exito = '';
    }

    cerrarEditor(): void {
      this.canalEditando = null;
      this.qrArchivo = null;
      this.qrPreview = '';
      this.error = '';
    }

    guardar(): void {
      if (!this.canalEditando) {
        return;
      }

      if (!this.canalEditando.metodoPago?.trim()) {
        this.error = 'El método de pago es obligatorio.';
        return;
      }

      if (!this.canalEditando.titular?.trim()) {
        this.error = 'El titular es obligatorio.';
        return;
      }

      if (this.esBilletera() && !this.canalEditando.numero?.trim()) {
        this.error = 'Ingrese el número de celular para Yape o Plin.';
        return;
      }

      if (this.esTransferencia()) {
        if (!this.canalEditando.banco?.trim()) {
          this.error = 'Seleccione el banco.';
          return;
        }

        if (!this.canalEditando.cuenta?.trim() && !this.canalEditando.cci?.trim()) {
          this.error = 'Ingrese al menos la cuenta o el CCI.';
          return;
        }
      }

      this.guardando = true;
      this.error = '';
      this.exito = '';

      const peticion = this.canalEditando.id
        ? this.canalPagoService.actualizar(
            this.canalEditando.id,
            this.canalEditando,
            this.qrArchivo || undefined
          )
        : this.canalPagoService.crear(
            this.canalEditando,
            this.qrArchivo || undefined
          );
      peticion.subscribe({
      next: (canalGuardado) => {
        const eraEdicion = Boolean(this.canalEditando?.id);

        this.exito = eraEdicion
          ? 'Canal de pago actualizado correctamente.'
          : 'Canal de pago creado correctamente.';

        if (this.qrPreview) {
          URL.revokeObjectURL(this.qrPreview);
        }

        this.qrArchivo = null;
        this.qrPreview = '';
        this.guardando = false;
        this.canalEditando = null;

        this.cargarCanales();
        this.cdr.detectChanges();
      },
        error: (err) => {
            console.error('Error al guardar canal:', err);
            console.error('Respuesta backend:', err?.error);

            if (typeof err?.error === 'string') {
              this.error = err.error;
            } else {
              this.error =
                err?.error?.message ||
                err?.error?.mensaje ||
                err?.error?.error ||
                `No se pudo guardar el canal de pago. Código HTTP: ${err?.status || 'desconocido'}`;
            }

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

    nuevoCanal(): void {
      this.canalEditando = {
        id: undefined as any,
        metodoPago: '',
        titular: '',
        numero: '',
        banco: '',
        cuenta: '',
        cci: '',
        descripcion: '',
        qrUrl: '',
        estado: true
      };

      this.qrArchivo = null;
      this.qrPreview = '';
      this.error = '';
      this.exito = '';
    }
      qrArchivo: File | null = null;
    qrPreview = '';

    seleccionarQr(event: Event): void {
      const input = event.target as HTMLInputElement;
      const archivo = input.files?.[0];

      if (!archivo) return;

      if (!['image/jpeg', 'image/png', 'image/webp'].includes(archivo.type)) {
        this.error = 'Solo se permiten imágenes JPG, PNG o WEBP.';
        return;
      }

      if (archivo.size > 3 * 1024 * 1024) {
        this.error = 'La imagen QR no debe superar los 3 MB.';
        return;
      }

      this.qrArchivo = archivo;
      this.qrPreview = URL.createObjectURL(archivo);
      this.error = '';
    }

    urlQr(url?: string): string {
      if (!url) return '';
      if (url.startsWith('http')) return url;
      return `${url}`;
    }

    esBilletera(): boolean {
  const metodo = String(this.canalEditando?.metodoPago || '').toUpperCase();
  return metodo === 'YAPE' || metodo === 'PLIN';
  }

  esTransferencia(): boolean {
    const metodo = String(this.canalEditando?.metodoPago || '').toUpperCase();
    return metodo === 'TRANSFERENCIA';
  }

  cambiarMetodoPago(): void {
    if (!this.canalEditando) {
      return;
    }

    const metodo = String(this.canalEditando.metodoPago || '').toUpperCase();

    if (metodo === 'YAPE' || metodo === 'PLIN') {
      this.canalEditando.banco = '';
      this.canalEditando.cuenta = '';
      this.canalEditando.cci = '';
    }

    if (metodo === 'TRANSFERENCIA') {
      this.canalEditando.numero = '';
    }

    this.error = '';
  }

}
