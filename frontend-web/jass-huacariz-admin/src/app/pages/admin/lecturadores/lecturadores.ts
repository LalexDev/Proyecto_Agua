import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { finalize } from 'rxjs';

import {
  Cliente,
  LecturadorRequest,
  LecturadorResponse
} from '../../../core/services/cliente';

@Component({
  selector: 'app-lecturadores',
  imports: [CommonModule, FormsModule],
  templateUrl: './lecturadores.html',
  styleUrl: './lecturadores.scss',
})
export class Lecturadores implements OnInit {
  lecturadores: LecturadorResponse[] = [];
  lecturadoresFiltrados: LecturadorResponse[] = [];

  cargando = false;
  guardando = false;

  error = '';
  exito = '';

  busqueda = '';
  filtroEstado = 'TODOS';


  mostrarConfirmacion = false;
  accionConfirmacion: 'ESTADO' | 'ELIMINAR' | null = null;
  lecturadorSeleccionado: LecturadorResponse | null = null;

  mostrarFormulario = false;
  modoEdicion = false;
  lecturadorEditandoId: number | null = null;

  form: LecturadorRequest = this.crearFormularioVacio();

  constructor(
    private clienteService: Cliente,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarLecturadores();
  }

  cargarLecturadores(): void {
    this.cargando = true;
    this.error = '';
    this.exito = '';

    this.clienteService.listarLecturadores()
      .pipe(
        finalize(() => {
          this.cargando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (data) => {
          this.lecturadores = data || [];
          this.aplicarFiltros();
          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudieron cargar los lecturadores.';
          this.lecturadores = [];
          this.lecturadoresFiltrados = [];
          this.cdr.detectChanges();
        }
      });
  }

  aplicarFiltros(): void {
    const texto = this.busqueda.trim().toLowerCase();

    this.lecturadoresFiltrados = this.lecturadores.filter((item) => {
      const coincideTexto =
        !texto ||
        String(item.dni || '').toLowerCase().includes(texto) ||
        this.nombreCompleto(item).toLowerCase().includes(texto) ||
        String(item.telefono || '').toLowerCase().includes(texto) ||
        String(item.correo || '').toLowerCase().includes(texto) ||
        String(item.codigoUsuario || '').toLowerCase().includes(texto) ||
        String(item.sectorAsignado || '').toLowerCase().includes(texto);

      const coincideEstado =
        this.filtroEstado === 'TODOS' ||
        (this.filtroEstado === 'ACTIVO' && item.estado) ||
        (this.filtroEstado === 'INACTIVO' && !item.estado);

      return coincideTexto && coincideEstado;
    });
  }

  limpiarFiltros(): void {
    this.busqueda = '';
    this.filtroEstado = 'TODOS';
    this.aplicarFiltros();
  }

  abrirNuevo(): void {
    this.mostrarFormulario = true;
    this.modoEdicion = false;
    this.lecturadorEditandoId = null;
    this.error = '';
    this.exito = '';
    this.form = this.crearFormularioVacio();
  }

  abrirEditar(item: LecturadorResponse): void {
    this.mostrarFormulario = true;
    this.modoEdicion = true;
    this.lecturadorEditandoId = item.id;
    this.error = '';
    this.exito = '';

    this.form = {
      dni: item.dni || '',
      nombres: item.nombres || '',
      apellidos: item.apellidos || '',
      telefono: item.telefono || '',
      correo: item.correo || '',
      codigoUsuario: item.codigoUsuario || '',
      password: '',
      estado: item.estado,
      sectorAsignado: item.sectorAsignado || ''
    };
  }

  cerrarFormulario(): void {
    this.mostrarFormulario = false;
    this.modoEdicion = false;
    this.lecturadorEditandoId = null;
    this.error = '';
    this.form = this.crearFormularioVacio();
  }

  guardarLecturador(): void {
    this.error = '';
    this.exito = '';

    if (!this.validarFormulario()) {
      return;
    }

    this.guardando = true;

    const payload: LecturadorRequest = {
      dni: this.form.dni.trim(),
      nombres: this.form.nombres.trim(),
      apellidos: this.form.apellidos.trim(),
      telefono: this.form.telefono.trim(),
      correo: this.form.correo.trim(),
      codigoUsuario: this.form.codigoUsuario.trim(),
      password: this.form.password.trim(),
      estado: this.form.estado,
      sectorAsignado: this.form.sectorAsignado?.trim() || ''
    };

    const request$ = this.modoEdicion && this.lecturadorEditandoId
      ? this.clienteService.actualizarLecturador(this.lecturadorEditandoId, payload)
      : this.clienteService.registrarLecturador(payload);

    request$
      .pipe(
        finalize(() => {
          this.guardando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: () => {
          this.exito = this.modoEdicion
            ? 'Lecturador actualizado correctamente.'
            : 'Lecturador registrado correctamente.';

          this.cerrarFormulario();
          this.cargarLecturadores();
        },
        error: (err) => {
          this.error = err?.error?.error || err?.error?.message || 'No se pudo guardar el lecturador.';
          this.cdr.detectChanges();
        }
      });
  }

    cambiarEstado(item: LecturadorResponse): void {
      this.lecturadorSeleccionado = item;
      this.accionConfirmacion = 'ESTADO';
      this.mostrarConfirmacion = true;
    }

    eliminarLecturador(item: LecturadorResponse): void {
      this.lecturadorSeleccionado = item;
      this.accionConfirmacion = 'ELIMINAR';
      this.mostrarConfirmacion = true;
    }

  totalLecturadores(): number {
    return this.lecturadores.length;
  }

  lecturadoresActivos(): number {
    return this.lecturadores.filter(l => l.estado).length;
  }

  lecturadoresInactivos(): number {
    return this.lecturadores.filter(l => !l.estado).length;
  }

  sectoresAsignados(): number {
    const sectores = new Set(
      this.lecturadores
        .map(l => (l.sectorAsignado || '').trim().toLowerCase())
        .filter(Boolean)
    );

    return sectores.size;
  }

  nombreCompleto(item: LecturadorResponse): string {
    return `${item.nombres || ''} ${item.apellidos || ''}`.trim();
  }

  estadoTexto(estado: boolean): string {
    return estado ? 'Activo' : 'Inactivo';
  }

  estadoClase(estado: boolean): string {
    return estado ? 'activo' : 'inactivo';
  }

  private validarFormulario(): boolean {
    if (!this.form.dni || this.form.dni.trim().length !== 8) {
      this.error = 'Ingrese un DNI válido de 8 dígitos.';
      return false;
    }

    if (!this.form.nombres.trim()) {
      this.error = 'Ingrese los nombres del lecturador.';
      return false;
    }

    if (!this.form.apellidos.trim()) {
      this.error = 'Ingrese los apellidos del lecturador.';
      return false;
    }

    if (!this.form.codigoUsuario.trim()) {
      this.error = 'Ingrese el usuario de acceso.';
      return false;
    }

    if (!this.modoEdicion && (!this.form.password.trim() || this.form.password.trim().length < 6)) {
      this.error = 'Ingrese una contraseña inicial de mínimo 6 caracteres.';
      return false;
    }

    if (this.modoEdicion && this.form.password.trim() && this.form.password.trim().length < 6) {
      this.error = 'La nueva contraseña debe tener mínimo 6 caracteres.';
      return false;
    }

    return true;
  }

  private crearFormularioVacio(): LecturadorRequest {
    return {
      dni: '',
      nombres: '',
      apellidos: '',
      telefono: '',
      correo: '',
      codigoUsuario: '',
      password: 'lector123',
      estado: true,
      sectorAsignado: ''
    };
  }


    cerrarConfirmacion(): void {
    this.mostrarConfirmacion = false;
    this.accionConfirmacion = null;
    this.lecturadorSeleccionado = null;
  }

  confirmarAccion(): void {
    if (!this.lecturadorSeleccionado || !this.accionConfirmacion) {
      return;
    }

    if (this.accionConfirmacion === 'ESTADO') {
      const item = this.lecturadorSeleccionado;
      const nuevoEstado = !item.estado;

      this.clienteService.cambiarEstadoLecturador(item.id, nuevoEstado)
        .subscribe({
          next: () => {
            this.exito = nuevoEstado
              ? 'Lecturador activado correctamente.'
              : 'Lecturador inactivado correctamente.';

            this.cerrarConfirmacion();
            this.cargarLecturadores();
          },
          error: (err) => {
            this.error = err?.error?.error || 'No se pudo cambiar el estado del lecturador.';
            this.cerrarConfirmacion();
            this.cdr.detectChanges();
          }
        });

      return;
    }

    if (this.accionConfirmacion === 'ELIMINAR') {
      const item = this.lecturadorSeleccionado;

      this.clienteService.eliminarLecturador(item.id)
        .subscribe({
          next: () => {
            this.exito = 'Lecturador eliminado correctamente.';
            this.cerrarConfirmacion();
            this.cargarLecturadores();
          },
          error: (err) => {
            this.error = err?.error?.error || 'No se pudo eliminar el lecturador.';
            this.cerrarConfirmacion();
            this.cdr.detectChanges();
          }
        });
    }
  }

  tituloConfirmacion(): string {
    if (!this.lecturadorSeleccionado) return '';

    if (this.accionConfirmacion === 'ELIMINAR') {
      return 'Eliminar lecturador';
    }

    return this.lecturadorSeleccionado.estado
      ? 'Inactivar lecturador'
      : 'Activar lecturador';
  }

  mensajeConfirmacion(): string {
    if (!this.lecturadorSeleccionado) return '';

    const nombre = this.nombreCompleto(this.lecturadorSeleccionado);

    if (this.accionConfirmacion === 'ELIMINAR') {
      return `¿Deseas eliminar al lecturador ${nombre}? También se eliminará su usuario de acceso.`;
    }

    return this.lecturadorSeleccionado.estado
      ? `¿Deseas inactivar al lecturador ${nombre}? No podrá iniciar sesión.`
      : `¿Deseas activar al lecturador ${nombre}? Podrá iniciar sesión nuevamente.`;
  }

  textoBotonConfirmacion(): string {
    if (this.accionConfirmacion === 'ELIMINAR') return 'Eliminar lecturador';

    return this.lecturadorSeleccionado?.estado
      ? 'Inactivar lecturador'
      : 'Activar lecturador';
  }
}