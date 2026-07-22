import { CommonModule, Location } from '@angular/common';
import { ChangeDetectorRef, Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { finalize } from 'rxjs';

import {
  CambiarPasswordRequest,
  ClientePortal
} from '../../../core/services/cliente-portal';

@Component({
  selector: 'app-contrasena',
  imports: [CommonModule, FormsModule],
  templateUrl: './contrasena.html',
  styleUrl: './contrasena.scss',
})
export class Contrasena {
  cargando = false;
  error = '';
  exito = '';

  mostrarActual = false;
  mostrarNueva = false;
  mostrarConfirmar = false;

  form: CambiarPasswordRequest = {
    passwordActual: '',
    nuevaPassword: '',
    confirmarPassword: ''
  };

  constructor(
    private clientePortal: ClientePortal,
    private location: Location,
    private cdr: ChangeDetectorRef
  ) {}

  volver(): void {
    this.location.back();
  }

  cambiarPassword(): void {
    this.error = '';
    this.exito = '';

    if (!this.form.passwordActual.trim()) {
      this.error = 'Ingrese su contraseña actual.';
      return;
    }

    if (!this.form.nuevaPassword.trim()) {
      this.error = 'Ingrese la nueva contraseña.';
      return;
    }

    if (this.form.nuevaPassword.length < 6) {
      this.error = 'La nueva contraseña debe tener como máximo 6 caracteres.';
      return;
    }

    if (!this.form.confirmarPassword.trim()) {
      this.error = 'Confirme la nueva contraseña.';
      return;
    }

    if (this.form.nuevaPassword !== this.form.confirmarPassword) {
      this.error = 'La nueva contraseña y la confirmación no coinciden.';
      return;
    }

    if (this.form.passwordActual === this.form.nuevaPassword) {
      this.error = 'La nueva contraseña debe ser diferente a la actual.';
      return;
    }

    this.cargando = true;

    const payload: CambiarPasswordRequest = {
      passwordActual: this.form.passwordActual.trim(),
      nuevaPassword: this.form.nuevaPassword.trim(),
      confirmarPassword: this.form.confirmarPassword.trim()
    };

    this.clientePortal.cambiarMiPassword(payload)
      .pipe(
        finalize(() => {
          this.cargando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (response) => {
          this.exito = response?.mensaje || 'Contraseña actualizada correctamente.';
          this.limpiarFormulario();
          this.cdr.detectChanges();
        },
        error: (err) => {
          this.error =
            err?.error?.mensaje ||
            err?.error?.error ||
            'No se pudo cambiar la contraseña. Verifique su contraseña actual.';
          this.cdr.detectChanges();
        }
      });
  }

  limpiarFormulario(): void {
    this.form = {
      passwordActual: '',
      nuevaPassword: '',
      confirmarPassword: ''
    };

    this.mostrarActual = false;
    this.mostrarNueva = false;
    this.mostrarConfirmar = false;
  }

  seguridadPassword(): number {
    const value = this.form.nuevaPassword || '';
    let score = 0;

    if (value.length >= 6) score += 25;
    if (value.length >= 10) score += 20;
    if (/[A-Z]/.test(value)) score += 15;
    if (/[0-9]/.test(value)) score += 15;
    if (/[^A-Za-z0-9]/.test(value)) score += 25;

    return Math.min(score, 100);
  }

  textoSeguridad(): string {
    const score = this.seguridadPassword();

    if (!this.form.nuevaPassword) {
      return 'Sin evaluar';
    }

    if (score < 40) {
      return 'Debil';
    }

    if (score < 75) {
      return 'Media';
    }

    return 'Fuerte';
  }

  claseSeguridad(): string {
    const score = this.seguridadPassword();

    if (!this.form.nuevaPassword) {
      return 'neutral';
    }

    if (score < 40) {
      return 'debil';
    }

    if (score < 75) {
      return 'media';
    }

    return 'fuerte';
  }

  usuarioActual(): string {
    return localStorage.getItem('nombreUsuario') ||
      localStorage.getItem('codigoUsuario') ||
      'Cliente JASS';
  }

  codigoUsuario(): string {
    return localStorage.getItem('codigoUsuario') || 'Usuario cliente';
  }

  iniciales(): string {
    const nombre = this.usuarioActual();
    const partes = nombre.split(' ').filter(Boolean);

    if (partes.length >= 2) {
      return `${partes[0][0]}${partes[1][0]}`.toUpperCase();
    }

    return nombre.substring(0, 1).toUpperCase();
  }
}
