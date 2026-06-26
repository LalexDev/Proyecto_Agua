import { CommonModule, Location } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterModule } from '@angular/router';
import { finalize } from 'rxjs';

import {
  ClientePortal,
  PagoRequest,
  ReciboClienteResponse
} from '../../../core/services/cliente-portal';

import { imprimirReciboJass } from '../../../core/utils/recibo-print';

import {
  CanalPago,
  CanalPagoResponse
} from '../../../core/services/canal-pago';

interface MetodoPagoCliente {
  codigo: string;
  nombre: string;
  descripcion: string;
  icono: string;
}

@Component({
  selector: 'app-pagar-recibo',
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './pagar-recibo.html',
  styleUrl: './pagar-recibo.scss',
})
export class PagarRecibo implements OnInit {
  idRecibo = 0;

  recibo: ReciboClienteResponse | null = null;
  recibos: ReciboClienteResponse[] = [];
  canalesPago: CanalPagoResponse[] = [];

  comprobanteArchivo: File | null = null;
  comprobantePreview = '';

  cargando = false;
  procesando = false;
  error = '';
  exito = '';

  metodosPago: MetodoPagoCliente[] = [
    {
      codigo: 'YAPE',
      nombre: 'Yape',
      descripcion: 'Paga desde tu aplicación Yape y registra el número de operación.',
      icono: 'Y'
    },
    {
      codigo: 'PLIN',
      nombre: 'Plin',
      descripcion: 'Paga desde tu aplicación bancaria con Plin.',
      icono: 'P'
    },
    {
      codigo: 'TRANSFERENCIA',
      nombre: 'Transferencia bancaria',
      descripcion: 'Realiza una transferencia y registra el código de operación.',
      icono: 'T'
    },

  ];

  pago: PagoRequest = {
    metodoPago: 'YAPE',
    codigoOperacion: ''
  };

  constructor(
    private route: ActivatedRoute,
    private location: Location,
    private clientePortal: ClientePortal,
    private cdr: ChangeDetectorRef,
    private canalPagoService: CanalPago,
    
  ) {}

  ngOnInit(): void {
    this.cargarCanalesPago();
    this.route.paramMap.subscribe((params) => {
      this.idRecibo = Number(params.get('id') || 0);
      this.cargarRecibo();
    });
  }

  cargarRecibo(): void {
    if (!this.idRecibo) {
      this.error = 'No se recibió el ID del recibo.';
      return;
    }

    this.cargando = true;
    this.error = '';
    this.exito = '';

    this.clientePortal.obtenerReciboPorId(this.idRecibo)
      .pipe(
        finalize(() => {
          this.cargando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (data) => {
          this.recibo = data;
          this.cargarHistorialParaImpresion();
          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudo cargar el recibo seleccionado.';
          this.recibo = null;
          this.cdr.detectChanges();
        }
      });
  }

  cargarHistorialParaImpresion(): void {
    this.clientePortal.listarMisRecibos().subscribe({
      next: (data) => {
        this.recibos = data || [];
        this.cdr.detectChanges();
      },
      error: () => {
        this.recibos = [];
        this.cdr.detectChanges();
      }
    });
  }

  seleccionarMetodo(codigo: string): void {
    this.pago.metodoPago = codigo;
    this.error = '';
    this.exito = '';
  }

  metodoSeleccionado(): MetodoPagoCliente | null {
    return this.metodosPago.find((item) => item.codigo === this.pago.metodoPago) || null;
  }

  seleccionarComprobante(event: Event): void {
    const input = event.target as HTMLInputElement;
    const archivo = input.files?.[0];

    if (!archivo) {
      return;
    }

    if (!['image/jpeg', 'image/png', 'image/webp'].includes(archivo.type)) {
      this.error = 'Solo se permiten imágenes JPG, PNG o WEBP.';
      this.comprobanteArchivo = null;
      this.comprobantePreview = '';
      input.value = '';
      return;
    }

    if (archivo.size > 3 * 1024 * 1024) {
      this.error = 'La imagen no debe superar los 3 MB.';
      this.comprobanteArchivo = null;
      this.comprobantePreview = '';
      input.value = '';
      return;
    }

    if (this.comprobantePreview) {
      URL.revokeObjectURL(this.comprobantePreview);
    }

    this.comprobanteArchivo = archivo;
    this.comprobantePreview = URL.createObjectURL(archivo);
    this.error = '';
  }

  confirmarPago(): void {
    if (!this.recibo) {
      this.error = 'No hay recibo seleccionado.';
      return;
    }

    if (!this.puedePagar()) {
      this.error = 'Este recibo ya se encuentra pagado o está en revisión.';
      return;
    }

    if (!this.pago.metodoPago || !this.pago.metodoPago.trim()) {
      this.error = 'Seleccione un método de pago.';
      return;
    }

    if (!this.pago.codigoOperacion || !this.pago.codigoOperacion.trim()) {
      this.error = 'Ingrese el código o número de operación.';
      return;
    }

    if (this.pago.codigoOperacion.trim().length < 4) {
      this.error = 'El código de operación debe tener al menos 4 caracteres.';
      return;
    }

    if (!this.comprobanteArchivo) {
      this.error = 'Debe subir una captura del comprobante.';
      return;
    }

    this.procesando = true;
    this.error = '';
    this.exito = '';

    this.clientePortal.pagarMiRecibo(
      this.recibo.id,
      this.pago.metodoPago.trim(),
      this.pago.codigoOperacion.trim(),
      this.comprobanteArchivo
    )
      .pipe(
        finalize(() => {
          this.procesando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: () => {
          this.exito = 'Tu pago fue enviado para revisión. Agua Potable Huacariz confirmará el pago cuando valide la operación.';
          this.pago.codigoOperacion = '';
          this.comprobanteArchivo = null;

          if (this.comprobantePreview) {
            URL.revokeObjectURL(this.comprobantePreview);
          }

          this.comprobantePreview = '';
          this.cargarRecibo();
        },
        error: (err) => {
          this.error = err?.error?.error ||
            err?.error?.mensaje ||
            'No se pudo enviar el pago. Verifica el código de operación y la captura.';
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

    imprimirReciboJass(this.recibo, this.recibos);
  }

  puedePagar(): boolean {
    if (!this.recibo) {
      return false;
    }

    const estado = String(this.recibo.estadoRecibo || '').toUpperCase();

    return estado !== 'PAGADO' && estado !== 'PAGO_EN_REVISION';
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

  estadoClase(estado?: string): string {
    const valor = String(estado || '').toLowerCase();

    if (valor === 'pagado') {
      return 'pagado';
    }

    if (valor === 'vencido') {
      return 'vencido';
    }

    if (valor === 'pago_en_revision') {
      return 'revision';
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


  cargarCanalesPago(): void {
    this.canalPagoService.listarActivos().subscribe({
      next: (data) => {
        this.canalesPago = data || [];
        this.cdr.detectChanges();
      },
      error: () => {
        this.canalesPago = [];
        this.cdr.detectChanges();
      }
    });
  }

  canalSeleccionado(): CanalPagoResponse | null {
    const metodo = String(this.pago.metodoPago || '').toUpperCase();

    return this.canalesPago.find((item) => {
      return String(item.metodoPago || '').toUpperCase() === metodo;
    }) || null;
  }
}