import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { finalize } from 'rxjs';

import { Auth } from '../../../core/services/auth';
import { ClientePortal } from '../../../core/services/cliente-portal';

@Component({
  selector: 'app-contrasena',
  imports: [CommonModule, FormsModule],
  templateUrl: './contrasena.html',
  styleUrl: './contrasena.scss',
})
export class Contrasena {
  guardando = false;
  error = '';
  exito = '';

  mostrarActual = false;
  mostrarNueva = false;
  mostrarConfirmar = false;

  form = {
    contrasenaActual: '',
    nuevaContrasena: '',
    confirmarContrasena: ''
  };

  constructor(
    private clientePortal: ClientePortal,
    private auth: Auth,
    private cdr: ChangeDetectorRef
  ) {}

  cambiarContrasena(): void {
    this.error = '';
    this.exito = '';

    if (!this.validarFormulario()) {
      return;
    }

    const payload = {
      contrasenaActual: this.form.contrasenaActual.trim(),
      nuevaContrasena: this.form.nuevaContrasena.trim(),
      confirmarContrasena: this.form.confirmarContrasena.trim(),
      passwordActual: this.form.contrasenaActual.trim(),
      passwordNueva: this.form.nuevaContrasena.trim(),
      passwordConfirmacion: this.form.confirmarContrasena.trim(),
      currentPassword: this.form.contrasenaActual.trim(),
      newPassword: this.form.nuevaContrasena.trim(),
      confirmPassword: this.form.confirmarContrasena.trim()
    };

    const servicios: any[] = [
      this.clientePortal as any,
      this.auth as any
    ];

    let peticion: any = null;

    for (const servicio of servicios) {
      if (!servicio) {
        continue;
      }

      if (typeof servicio.cambiarContrasena === 'function') {
        peticion = servicio.cambiarContrasena(payload);
        break;
      }

      if (typeof servicio.cambiarPassword === 'function') {
        peticion = servicio.cambiarPassword(payload);
        break;
      }

      if (typeof servicio.actualizarContrasena === 'function') {
        peticion = servicio.actualizarContrasena(payload);
        break;
      }

      if (typeof servicio.actualizarPassword === 'function') {
        peticion = servicio.actualizarPassword(payload);
        break;
      }

      if (typeof servicio.cambiarMiContrasena === 'function') {
        peticion = servicio.cambiarMiContrasena(payload);
        break;
      }

      if (typeof servicio.changePassword === 'function') {
        peticion = servicio.changePassword(payload);
        break;
      }
    }

    if (!peticion) {
      this.error = 'No se encontró el método para cambiar contraseña en el frontend. Revisa cliente-portal.ts o auth.ts.';
      return;
    }

    this.guardando = true;

    peticion
      .pipe(
        finalize(() => {
          this.guardando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: () => {
          this.exito = 'Contraseña actualizada correctamente.';
          this.limpiarFormulario();
          this.cdr.detectChanges();
        },
        error: (err: any) => {
          this.error = err?.error?.error ||
            err?.error?.message ||
            'No se pudo actualizar la contraseña. Verifica tu contraseña actual.';
          this.cdr.detectChanges();
        }
      });
  }

  validarFormulario(): boolean {
    if (!this.form.contrasenaActual.trim()) {
      this.error = 'Ingresa tu contraseña actual.';
      return false;
    }

    if (!this.form.nuevaContrasena.trim()) {
      this.error = 'Ingresa tu nueva contraseña.';
      return false;
    }

    if (this.form.nuevaContrasena.trim().length < 6) {
      this.error = 'La nueva contraseña debe tener como mínimo 6 caracteres.';
      return false;
    }

    if (this.form.nuevaContrasena.trim() !== this.form.confirmarContrasena.trim()) {
      this.error = 'La confirmación no coincide con la nueva contraseña.';
      return false;
    }

    if (this.form.contrasenaActual.trim() === this.form.nuevaContrasena.trim()) {
      this.error = 'La nueva contraseña debe ser diferente a la contraseña actual.';
      return false;
    }

    return true;
  }

  limpiarFormulario(): void {
    this.form = {
      contrasenaActual: '',
      nuevaContrasena: '',
      confirmarContrasena: ''
    };
  }

  seguridadContrasena(): number {
    const value = this.form.nuevaContrasena || '';
    let score = 0;

    if (value.length >= 6) {
      score += 25;
    }

    if (value.length >= 10) {
      score += 25;
    }

    if (/[A-Z]/.test(value)) {
      score += 15;
    }

    if (/[0-9]/.test(value)) {
      score += 15;
    }

    if (/[^A-Za-z0-9]/.test(value)) {
      score += 20;
    }

    return Math.min(score, 100);
  }

  textoSeguridad(): string {
    const score = this.seguridadContrasena();

    if (!this.form.nuevaContrasena) {
      return 'Sin evaluar';
    }

    if (score < 40) {
      return 'Débil';
    }

    if (score < 75) {
      return 'Media';
    }

    return 'Fuerte';
  }

  claseSeguridad(): string {
    const score = this.seguridadContrasena();

    if (!this.form.nuevaContrasena) {
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
}