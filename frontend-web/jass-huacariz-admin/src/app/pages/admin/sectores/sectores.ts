import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { finalize } from 'rxjs';

import {
  Cliente,
  SectorRequest,
  SectorResponse
} from '../../../core/services/cliente';

@Component({
  selector: 'app-sectores',
  imports: [CommonModule, FormsModule],
  templateUrl: './sectores.html',
  styleUrl: './sectores.scss',
})
export class Sectores implements OnInit {
  sectores: SectorResponse[] = [];
  sectoresFiltrados: SectorResponse[] = [];

  busqueda = '';
  filtroEstado: 'TODOS' | 'ACTIVO' | 'INACTIVO' = 'TODOS';

  cargando = false;
  guardando = false;
  error = '';
  exito = '';

  mostrarFormulario = false;
  editando = false;
  sectorEditando: SectorResponse | null = null;

  formSector: SectorRequest = this.crearFormularioVacio();

  constructor(
    private clienteService: Cliente,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarSectores();
  }

  cargarSectores(): void {
    this.cargando = true;
    this.error = '';
    this.exito = '';

    this.clienteService.listarSectores()
      .pipe(
        finalize(() => {
          this.cargando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (data) => {
          this.sectores = data || [];
          this.aplicarFiltros();
          this.cdr.detectChanges();
        },
        error: () => {
          this.error = 'No se pudieron cargar los sectores.';
          this.sectores = [];
          this.sectoresFiltrados = [];
          this.cdr.detectChanges();
        }
      });
  }

  aplicarFiltros(): void {
    const texto = this.busqueda.trim().toLowerCase();

    this.sectoresFiltrados = this.sectores.filter((sector) => {
      const coincideTexto =
        !texto ||
        String(sector.nombre || '').toLowerCase().includes(texto) ||
        String(sector.descripcion || '').toLowerCase().includes(texto);

      const coincideEstado =
        this.filtroEstado === 'TODOS' ||
        (this.filtroEstado === 'ACTIVO' && sector.estado) ||
        (this.filtroEstado === 'INACTIVO' && !sector.estado);

      return coincideTexto && coincideEstado;
    });
  }

  limpiarFiltros(): void {
    this.busqueda = '';
    this.filtroEstado = 'TODOS';
    this.aplicarFiltros();
  }

  abrirNuevo(): void {
    this.error = '';
    this.exito = '';
    this.editando = false;
    this.sectorEditando = null;
    this.formSector = this.crearFormularioVacio();
    this.mostrarFormulario = true;
  }

  abrirEditar(sector: SectorResponse): void {
    this.error = '';
    this.exito = '';
    this.editando = true;
    this.sectorEditando = sector;

    this.formSector = {
      nombre: sector.nombre || '',
      descripcion: sector.descripcion || '',
      estado: sector.estado
    };

    this.mostrarFormulario = true;
  }

  cerrarFormulario(): void {
    if (this.guardando) {
      return;
    }

    this.mostrarFormulario = false;
    this.editando = false;
    this.sectorEditando = null;
    this.formSector = this.crearFormularioVacio();
    this.error = '';
  }

  guardarSector(): void {
    this.error = '';
    this.exito = '';

    if (!this.formSector.nombre.trim()) {
      this.error = 'Ingrese el nombre del sector.';
      return;
    }

    this.guardando = true;

    const payload: SectorRequest = {
      nombre: this.formSector.nombre.trim().toUpperCase(),
      descripcion: this.formSector.descripcion?.trim() || '',
      estado: this.formSector.estado
    };

    const request$ = this.editando && this.sectorEditando
      ? this.clienteService.actualizarSector(this.sectorEditando.id, payload)
      : this.clienteService.registrarSector(payload);

    request$
      .pipe(
        finalize(() => {
          this.guardando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: () => {
          this.exito = this.editando
            ? 'Sector actualizado correctamente.'
            : 'Sector registrado correctamente.';

          this.mostrarFormulario = false;
          this.editando = false;
          this.sectorEditando = null;
          this.formSector = this.crearFormularioVacio();
          this.cargarSectores();
        },
        error: (err) => {
          this.error = err?.error?.error || err?.error?.mensaje || 'No se pudo guardar el sector.';
          this.cdr.detectChanges();
        }
      });
  }

  cambiarEstado(sector: SectorResponse): void {
    const nuevoEstado = !sector.estado;

    const confirmar = confirm(
      nuevoEstado
        ? `¿Deseas activar el sector ${sector.nombre}?`
        : `¿Deseas desactivar el sector ${sector.nombre}?`
    );

    if (!confirmar) {
      return;
    }

    this.error = '';
    this.exito = '';

    this.clienteService.cambiarEstadoSector(sector.id, nuevoEstado).subscribe({
      next: () => {
        this.exito = nuevoEstado
          ? 'Sector activado correctamente.'
          : 'Sector desactivado correctamente.';

        this.cargarSectores();
      },
      error: (err) => {
        this.error = err?.error?.error || err?.error?.mensaje || 'No se pudo cambiar el estado del sector.';
        this.cdr.detectChanges();
      }
    });
  }

  totalSectores(): number {
    return this.sectores.length;
  }

  sectoresActivos(): number {
    return this.sectores.filter((sector) => sector.estado).length;
  }

  sectoresInactivos(): number {
    return this.sectores.filter((sector) => !sector.estado).length;
  }

  estadoTexto(estado: boolean): string {
    return estado ? 'Activo' : 'Inactivo';
  }

  estadoClase(estado: boolean): string {
    return estado ? 'activo' : 'inactivo';
  }

  private crearFormularioVacio(): SectorRequest {
    return {
      nombre: '',
      descripcion: '',
      estado: true
    };
  }
}