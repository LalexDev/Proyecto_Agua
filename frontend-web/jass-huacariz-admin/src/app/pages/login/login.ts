import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { finalize } from 'rxjs';

interface LoginResponse {
  token: string;
  tipoToken: string;
  codigoUsuario: string;
  rol: string;
  expiracion: number;
  mensaje: string;
}

@Component({
  selector: 'app-login',
  imports: [CommonModule, FormsModule],
  templateUrl: './login.html',
  styleUrl: './login.scss',
})
export class Login {
  codigoUsuario = '';
  password = '';

  cargando = false;
  error = '';

  mostrarLogin = false;
  mostrarPassword = false;

  private readonly apiUrl = 'https://qnsdd0d9-8080.brs.devtunnels.ms/api/auth/login';

  constructor(
    private http: HttpClient,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  abrirLogin(): void {
    this.mostrarLogin = true;
    this.error = '';

    setTimeout(() => {
      document.getElementById('codigoUsuario')?.focus();
    }, 150);
  }

  cerrarLogin(): void {
    if (this.cargando) {
      return;
    }

    this.mostrarLogin = false;
    this.error = '';
    this.password = '';
    this.mostrarPassword = false;
  }

  alternarPassword(): void {
    this.mostrarPassword = !this.mostrarPassword;
  }

  abrirLoginDesdeAccion(accion: string): void {
    this.abrirLogin();

    if (accion === 'recibo') {
      this.error = 'Para consultar tus recibos, primero inicia sesión.';
    }

    if (accion === 'pago') {
      this.error = 'Para registrar pagos, primero inicia sesión.';
    }

    if (accion === 'incidencia') {
      this.error = 'Para reportar una incidencia, primero inicia sesión.';
    }
  }

  iniciarSesion(): void {
    this.error = '';

    if (!this.codigoUsuario.trim()) {
      this.error = 'Ingrese su código de usuario.';
      return;
    }

    if (!this.password.trim()) {
      this.error = 'Ingrese su contraseña.';
      return;
    }

    this.cargando = true;

    const request = {
      codigoUsuario: this.codigoUsuario.trim(),
      password: this.password.trim()
    };

    this.http.post<LoginResponse>(this.apiUrl, request)
      .pipe(
        finalize(() => {
          this.cargando = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (response) => {
          const rol = response.rol?.toUpperCase();

          localStorage.setItem('token', response.token);
          localStorage.setItem('tipoToken', response.tipoToken || 'Bearer');
          localStorage.setItem('codigoUsuario', response.codigoUsuario);
          localStorage.setItem('rol', rol);
          localStorage.setItem('role', rol);
          localStorage.setItem('expiracion', String(response.expiracion));

          if (rol === 'ADMIN') {
            this.router.navigate(['/admin/dashboard']);
          } else if (rol === 'CLIENTE') {
            this.router.navigate(['/cliente/inicio']);
          } else if (rol === 'LECTURADOR') {
            this.router.navigate(['/lecturador/lecturas']);
          } else {
            this.error = 'Rol no autorizado.';
            localStorage.clear();
          }

          this.cdr.detectChanges();
        },
        error: (err) => {
          this.error = err?.error?.error || err?.error?.mensaje || 'Usuario o contraseña incorrectos.';
          this.cdr.detectChanges();
        }
      });
  }


   irSeccion(id: string): void {
  document.getElementById(id)?.scrollIntoView({
    behavior: 'smooth',
    block: 'start'
  });
}


  
}