import { CommonModule } from '@angular/common';
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
  form: CambiarPasswordRequest = {
    passwordActual: '',
    nuevaPassword: '',
    confirmarPassword: ''
  };

  cargando = false;
  error = '';
  exito = '';

  mostrarActual = false;
  mostrarNueva = false;
  mostrarConfirmar = false;

  constructor(
    private clientePortal: ClientePortal,
    private cdr: ChangeDetectorRef
  ) {}

  cambiarPassword(): void {
    this.error = '';
    this.exito = '';

    if (!this.validarFormulario()) {
      return;
    }

    this.cargando = true;

    this.clientePortal.cambiarMiPassword({
      passwordActual: this.form.passwordActual.trim(),
      nuevaPassword: this.form.nuevaPassword.trim(),
      confirmarPassword: this.form.confirmarPassword.trim()
    })
    .pipe(
      finalize(() => {
        this.cargando = false;
        this.cdr.detectChanges();
      })
    )
    .subscribe({
      next: (response) => {
        this.exito = response?.mensaje || 'Contraseña actualizada correctamente.';
        this.form = {
          passwordActual: '',
          nuevaPassword: '',
          confirmarPassword: ''
        };
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.error = err?.error?.error || err?.error?.mensaje || 'No se pudo actualizar la contraseña.';
        this.cdr.detectChanges();
      }
    });
  }

  private validarFormulario(): boolean {
    if (!this.form.passwordActual.trim()) {
      this.error = 'Ingrese su contraseña actual.';
      return false;
    }

    if (!this.form.nuevaPassword.trim()) {
      this.error = 'Ingrese la nueva contraseña.';
      return false;
    }

    if (this.form.nuevaPassword.trim().length < 6) {
      this.error = 'La nueva contraseña debe tener al menos 6 caracteres.';
      return false;
    }

    if (!this.form.confirmarPassword.trim()) {
      this.error = 'Confirme la nueva contraseña.';
      return false;
    }

    if (this.form.nuevaPassword.trim() !== this.form.confirmarPassword.trim()) {
      this.error = 'La nueva contraseña y la confirmación no coinciden.';
      return false;
    }

    if (this.form.passwordActual.trim() === this.form.nuevaPassword.trim()) {
      this.error = 'La nueva contraseña debe ser diferente a la actual.';
      return false;
    }

    return true;
  }
}