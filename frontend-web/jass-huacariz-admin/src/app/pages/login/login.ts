import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component } from '@angular/core';
import { Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { finalize } from 'rxjs';
import { Auth } from '../../core/services/auth';

@Component({
  selector: 'app-login',
  imports: [CommonModule, FormsModule],
  templateUrl: './login.html',
  styleUrl: './login.scss'
})
export class Login {
  codigoUsuario = '';
  password = '';
  cargando = false;
  error = '';

  constructor(
    private router: Router,
    private authService: Auth,
    private cdr: ChangeDetectorRef
  ) {}

  ingresar(rolEsperado: 'ADMIN' | 'CLIENTE'): void {
    this.error = '';

    if (!this.codigoUsuario.trim() || !this.password.trim()) {
      this.error = 'Ingrese usuario y contraseña.';
      this.cdr.detectChanges();
      return;
    }

    this.cargando = true;
    this.cdr.detectChanges();

    this.authService.login({
      codigoUsuario: this.codigoUsuario.trim(),
      password: this.password.trim()
    })
    .pipe(
      finalize(() => {
        this.cargando = false;
        this.cdr.detectChanges();
      })
    )
    .subscribe({
      next: (response) => {
        if (response.rol !== rolEsperado) {
          this.error = `Este usuario no pertenece al rol ${rolEsperado}.`;
          this.authService.logout();
          this.cdr.detectChanges();
          return;
        }

        if (response.rol === 'ADMIN') {
          this.router.navigate(['/admin/dashboard']);
          return;
        }

        if (response.rol === 'CLIENTE') {
          this.router.navigate(['/cliente/inicio']);
          return;
        }

        this.error = 'Rol no reconocido por el sistema.';
        this.authService.logout();
        this.cdr.detectChanges();
      },
      error: () => {
        this.error = 'Usuario o contraseña incorrectos.';
        this.authService.logout();
        this.cdr.detectChanges();
      }
    });
  }
}