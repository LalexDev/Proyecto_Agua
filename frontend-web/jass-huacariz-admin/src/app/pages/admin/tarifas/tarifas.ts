import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { finalize } from 'rxjs';

import {
  ConfiguracionCobranzaRequest,
  ConfiguracionCobranzaResponse,
  Tarifa,
  TarifaRequest,
  TarifaResponse
} from '../../../core/services/tarifa';

type TipoAccionTarifa = 'ESTADO' | 'ELIMINAR';

interface AccionTarifa {
  tipo: TipoAccionTarifa;
  tarifa: TarifaResponse;
  estadoNuevo?: boolean;
  titulo: string;
  mensaje: string;
  textoBoton: string;
}

@Component({
  selector: 'app-tarifas',
  imports: [CommonModule, FormsModule],
  templateUrl: './tarifas.html',
  styleUrl: './tarifas.scss',
})
export class Tarifas implements OnInit {
  tarifas: TarifaResponse[] = [];

  configuracion: ConfiguracionCobranzaResponse | null = null;
  configuracionForm: ConfiguracionCobranzaRequest = this.crearConfiguracionVacia();

  cargando = false;
  cargandoConfiguracion = false;
  guardando = false;
  guardandoConfiguracion = false;
  procesando = false;

  error = '';
  exito = '';

  mostrarFormulario = false;
  modoEdicion = false;
  tarifaEditandoId: number | null = null;

  accionPendiente: AccionTarifa | null = null;

  tarifaForm: TarifaRequest = this.crearTarifaVacia();

  constructor(
    private tarifaService: Tarifa,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarTarifas();
    this.cargarConfiguracionCobranza();
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
          this.tarifas = (data || []).sort((a, b) => {
            return Number(a.consumoDesde || 0) - Number(b.consumoDesde || 0);
          });

          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudieron cargar las tarifas. Verifica el backend y tu sesión ADMIN.';
          this.tarifas = [];
          this.cdr.detectChanges();
        }
      });
  }

  cargarConfiguracionCobranza(): void {
    this.cargandoConfiguracion = true;

    this.tarifaService.obtenerConfiguracionCobranza()
      .pipe(
        finalize(() => {
          this.cargandoConfiguracion = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (data) => {
          this.configuracion = data;

          this.configuracionForm = {
            cargoLector: Number(data.cargoLector || 0),
            cargoMantenimiento: Number(data.cargoMantenimiento || 0),
            cargoOtros: Number(data.cargoOtros || 0),
            diasVencimiento: Number(data.diasVencimiento || 15),
            moraBase: Number(data.moraBase || 0)
          };

          this.cdr.detectChanges();
        },
        error: () => {
          this.configuracionForm = this.crearConfiguracionVacia();
          this.cdr.detectChanges();
        }
      });
  }

  guardarConfiguracionCobranza(): void {
    this.error = '';
    this.exito = '';

    if (!this.validarConfiguracion()) {
      return;
    }

    this.guardandoConfiguracion = true;

    const payload: ConfiguracionCobranzaRequest = {
      cargoLector: Number(this.configuracionForm.cargoLector || 0),
      cargoMantenimiento: Number(this.configuracionForm.cargoMantenimiento || 0),
      cargoOtros: Number(this.configuracionForm.cargoOtros || 0),
      diasVencimiento: Number(this.configuracionForm.diasVencimiento || 15),
      moraBase: Number(this.configuracionForm.moraBase || 0)
    };

    this.tarifaService.guardarConfiguracionCobranza(payload)
      .pipe(
        finalize(() => {
          this.guardandoConfiguracion = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (data) => {
          this.configuracion = data;

          this.configuracionForm = {
            cargoLector: Number(data.cargoLector || 0),
            cargoMantenimiento: Number(data.cargoMantenimiento || 0),
            cargoOtros: Number(data.cargoOtros || 0),
            diasVencimiento: Number(data.diasVencimiento || 15),
            moraBase: Number(data.moraBase || 0)
          };

          this.exito = 'Configuración de cobranza actualizada correctamente.';
          this.cdr.detectChanges();
        },
        error: (err) => {
          this.error = err?.error?.error || 'No se pudo guardar la configuración de cobranza.';
          this.cdr.detectChanges();
        }
      });
  }

  abrirNuevaTarifa(): void {
    this.mostrarFormulario = true;
    this.modoEdicion = false;
    this.tarifaEditandoId = null;
    this.tarifaForm = this.crearTarifaVacia();
    this.error = '';
    this.exito = '';
  }

  abrirEditarTarifa(tarifa: TarifaResponse): void {
    this.mostrarFormulario = true;
    this.modoEdicion = true;
    this.tarifaEditandoId = tarifa.id;

    this.tarifaForm = {
      nombreTarifa: tarifa.nombreTarifa || '',
      consumoDesde: Number(tarifa.consumoDesde || 0),
      consumoHasta: tarifa.consumoHasta === null || tarifa.consumoHasta === undefined
        ? null
        : Number(tarifa.consumoHasta),
      precioM3: Number(tarifa.precioM3 || 0),
      estado: tarifa.estado
    };

    this.error = '';
    this.exito = '';
  }

  cerrarFormulario(): void {
    this.mostrarFormulario = false;
    this.modoEdicion = false;
    this.tarifaEditandoId = null;
    this.tarifaForm = this.crearTarifaVacia();
    this.error = '';
  }

  guardarTarifa(): void {
    this.error = '';
    this.exito = '';

    if (!this.validarFormulario()) {
      return;
    }

    this.guardando = true;

    const payload: TarifaRequest = {
      nombreTarifa: this.tarifaForm.nombreTarifa.trim(),
      consumoDesde: Number(this.tarifaForm.consumoDesde),
      consumoHasta: this.tarifaForm.consumoHasta === null ||
        this.tarifaForm.consumoHasta === undefined ||
        String(this.tarifaForm.consumoHasta).trim() === ''
          ? null
          : Number(this.tarifaForm.consumoHasta),
      precioM3: Number(this.tarifaForm.precioM3),
      estado: this.tarifaForm.estado
    };

    const peticion = this.modoEdicion && this.tarifaEditandoId
      ? this.tarifaService.actualizarTarifa(this.tarifaEditandoId, payload)
      : this.tarifaService.registrarTarifa(payload);

    peticion
      .pipe(
        finalize(() => {
          this.guardando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: () => {
          this.exito = this.modoEdicion
            ? 'Tarifa actualizada correctamente.'
            : 'Tarifa registrada correctamente.';

          this.cerrarFormulario();
          this.cargarTarifas();
        },
        error: (err) => {
          this.error = err?.error?.error || 'No se pudo guardar la tarifa.';
          this.cdr.detectChanges();
        }
      });
  }

  abrirCambiarEstado(tarifa: TarifaResponse): void {
    const estadoNuevo = !tarifa.estado;

    this.accionPendiente = {
      tipo: 'ESTADO',
      tarifa,
      estadoNuevo,
      titulo: estadoNuevo ? 'Activar tarifa' : 'Desactivar tarifa',
      mensaje: estadoNuevo
        ? `¿Deseas activar la tarifa "${tarifa.nombreTarifa}"?`
        : `¿Deseas desactivar la tarifa "${tarifa.nombreTarifa}"? Ya no se usará para nuevos cálculos.`,
      textoBoton: estadoNuevo ? 'Activar' : 'Desactivar'
    };
  }

  abrirEliminar(tarifa: TarifaResponse): void {
    this.accionPendiente = {
      tipo: 'ELIMINAR',
      tarifa,
      titulo: 'Eliminar tarifa',
      mensaje: `¿Deseas eliminar la tarifa "${tarifa.nombreTarifa}"? Se marcará como inactiva para no afectar recibos históricos.`,
      textoBoton: 'Eliminar'
    };
  }

  cerrarConfirmacion(): void {
    this.accionPendiente = null;
  }

  confirmarAccion(): void {
    if (!this.accionPendiente) {
      return;
    }

    this.procesando = true;
    this.error = '';
    this.exito = '';

    const accion = this.accionPendiente;

    if (accion.tipo === 'ESTADO') {
      this.tarifaService.cambiarEstadoTarifa(accion.tarifa.id, !!accion.estadoNuevo)
        .pipe(
          finalize(() => {
            this.procesando = false;
            this.cdr.detectChanges();
          })
        )
        .subscribe({
          next: () => {
            this.exito = accion.estadoNuevo
              ? 'Tarifa activada correctamente.'
              : 'Tarifa desactivada correctamente.';

            this.accionPendiente = null;
            this.cargarTarifas();
          },
          error: (err) => {
            this.error = err?.error?.error || 'No se pudo cambiar el estado de la tarifa.';
            this.cdr.detectChanges();
          }
        });

      return;
    }

    if (accion.tipo === 'ELIMINAR') {
      this.tarifaService.eliminarTarifa(accion.tarifa.id)
        .pipe(
          finalize(() => {
            this.procesando = false;
            this.cdr.detectChanges();
          })
        )
        .subscribe({
          next: () => {
            this.exito = 'Tarifa eliminada correctamente.';
            this.accionPendiente = null;
            this.cargarTarifas();
          },
          error: (err) => {
            this.error = err?.error?.error || 'No se pudo eliminar la tarifa.';
            this.cdr.detectChanges();
          }
        });
    }
  }

  totalTarifas(): number {
    return this.tarifas.length;
  }

  tarifasActivas(): number {
    return this.tarifas.filter((tarifa) => tarifa.estado).length;
  }

  tarifasInactivas(): number {
    return this.tarifas.filter((tarifa) => !tarifa.estado).length;
  }

  precioPromedio(): number {
    if (!this.tarifas.length) {
      return 0;
    }

    const total = this.tarifas.reduce((suma, tarifa) => suma + Number(tarifa.precioM3 || 0), 0);
    return total / this.tarifas.length;
  }

  precioMaximo(): number {
    if (!this.tarifas.length) {
      return 0;
    }

    return Math.max(...this.tarifas.map((tarifa) => Number(tarifa.precioM3 || 0)));
  }

  anchoBarra(tarifa: TarifaResponse): string {
    const maximo = this.precioMaximo();

    if (maximo <= 0) {
      return '0%';
    }

    const porcentaje = (Number(tarifa.precioM3 || 0) / maximo) * 100;
    return `${Math.max(porcentaje, 8)}%`;
  }

  estadoTexto(estado: boolean): string {
    return estado ? 'Activa' : 'Inactiva';
  }

  estadoClase(estado: boolean): string {
    return estado ? 'activa' : 'inactiva';
  }

  rangoConsumo(tarifa: TarifaResponse): string {
    if (tarifa.consumoHasta === null || tarifa.consumoHasta === undefined) {
      return `${tarifa.consumoDesde} m³ a más`;
    }

    return `${tarifa.consumoDesde} m³ - ${tarifa.consumoHasta} m³`;
  }

  consumoHastaTexto(tarifa: TarifaResponse): string {
    if (tarifa.consumoHasta === null || tarifa.consumoHasta === undefined) {
      return 'A más';
    }

    return `${tarifa.consumoHasta} m³`;
  }

  totalCargosConfigurados(): number {
    return Number(this.configuracionForm.cargoLector || 0)
      + Number(this.configuracionForm.cargoMantenimiento || 0)
      + Number(this.configuracionForm.cargoOtros || 0)
      + Number(this.configuracionForm.moraBase || 0);
  }

  private validarFormulario(): boolean {
    if (!this.tarifaForm.nombreTarifa || !this.tarifaForm.nombreTarifa.trim()) {
      this.error = 'Ingrese el nombre de la tarifa.';
      return false;
    }

    if (Number(this.tarifaForm.consumoDesde) < 0) {
      this.error = 'El consumo desde no puede ser negativo.';
      return false;
    }

    if (
      this.tarifaForm.consumoHasta !== null &&
      this.tarifaForm.consumoHasta !== undefined &&
      String(this.tarifaForm.consumoHasta).trim() !== '' &&
      Number(this.tarifaForm.consumoHasta) < Number(this.tarifaForm.consumoDesde)
    ) {
      this.error = 'El consumo hasta no puede ser menor al consumo desde.';
      return false;
    }

    if (Number(this.tarifaForm.precioM3) <= 0) {
      this.error = 'El precio por m³ debe ser mayor a cero.';
      return false;
    }

    return true;
  }

  private validarConfiguracion(): boolean {
    if (Number(this.configuracionForm.cargoLector) < 0) {
      this.error = 'El cargo del lector no puede ser negativo.';
      return false;
    }

    if (Number(this.configuracionForm.cargoMantenimiento) < 0) {
      this.error = 'El cargo de mantenimiento no puede ser negativo.';
      return false;
    }

    if (Number(this.configuracionForm.cargoOtros) < 0) {
      this.error = 'Otros cargos no puede ser negativo.';
      return false;
    }

    if (Number(this.configuracionForm.diasVencimiento) <= 0) {
      this.error = 'Los días de vencimiento deben ser mayor a cero.';
      return false;
    }

    if (Number(this.configuracionForm.moraBase) < 0) {
      this.error = 'La mora base no puede ser negativa.';
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

  private crearConfiguracionVacia(): ConfiguracionCobranzaRequest {
    return {
      cargoLector: 1.00,
      cargoMantenimiento: 3.00,
      cargoOtros: 0.20,
      diasVencimiento: 15,
      moraBase: 0.00
    };
  }
}
