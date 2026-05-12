import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-cambiar-password',
  imports: [FormsModule, RouterLink],
  templateUrl: './cambiar-password.html',
  styleUrl: './cambiar-password.scss'
})
export class CambiarPassword {
  passwordActual = '';
  nuevaPassword = '';
  confirmarPassword = '';

  mensajeExito = '';
  mensajeError = '';

  mostrarActual = false;
  mostrarNueva = false;
  mostrarConfirmar = false;

  get passwordCoincide(): boolean {
    return this.nuevaPassword === this.confirmarPassword;
  }

  get passwordValida(): boolean {
    return this.nuevaPassword.length >= 6;
  }

  cambiarPassword(): void {
    this.mensajeExito = '';
    this.mensajeError = '';

    if (!this.passwordActual || !this.nuevaPassword || !this.confirmarPassword) {
      this.mensajeError = 'Completa todos los campos para continuar.';
      return;
    }

    if (!this.passwordValida) {
      this.mensajeError = 'La nueva contraseña debe tener al menos 6 caracteres.';
      return;
    }

    if (!this.passwordCoincide) {
      this.mensajeError = 'La nueva contraseña y la confirmación no coinciden.';
      return;
    }

    this.mensajeExito = 'Contraseña actualizada correctamente.';
    this.passwordActual = '';
    this.nuevaPassword = '';
    this.confirmarPassword = '';
  }
}