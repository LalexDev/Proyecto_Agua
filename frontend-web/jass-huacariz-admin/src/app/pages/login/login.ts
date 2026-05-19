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

type RolSistema = 'ADMIN' | 'CLIENTE' | 'LECTURADOR';

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

  private readonly apiUrl = 'http://localhost:8080/api/auth/login';

  constructor(
    private http: HttpClient,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  ingresar(rolEsperado: RolSistema): void {
    this.iniciarSesion(rolEsperado);
  }

  iniciarSesion(rolEsperado: RolSistema): void {
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
          const rolRespuesta = response.rol?.toUpperCase() as RolSistema;

          if (rolRespuesta !== rolEsperado) {
            this.error = `Este usuario no pertenece al rol ${rolEsperado}.`;
            this.cdr.detectChanges();
            return;
          }

          localStorage.setItem('token', response.token);
          localStorage.setItem('tipoToken', response.tipoToken || 'Bearer');
          localStorage.setItem('codigoUsuario', response.codigoUsuario);
          localStorage.setItem('rol', rolRespuesta);
          localStorage.setItem('role', rolRespuesta);
          localStorage.setItem('expiracion', String(response.expiracion));

          if (rolRespuesta === 'ADMIN') {
            this.router.navigate(['/admin/dashboard']);
          } else if (rolRespuesta === 'CLIENTE') {
            this.router.navigate(['/cliente/inicio']);
          } else if (rolRespuesta === 'LECTURADOR') {
            this.router.navigate(['/lecturador/lecturas']);
          } else {
            this.error = 'Rol no autorizado.';
          }

          this.cdr.detectChanges();
        },
        error: (err) => {
          this.error = err?.error?.error || err?.error?.mensaje || 'Usuario o contraseña incorrectos.';
          this.cdr.detectChanges();
        }
      });
  }
}