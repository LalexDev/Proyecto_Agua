import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap } from 'rxjs';
import { Token } from './token';

export interface LoginRequest {
  codigoUsuario: string;
  password: string;
}

export interface LoginResponse {
  token: string;
  tipoToken: string;
  codigoUsuario: string;
  rol: string;
  expiracion: number;
  mensaje: string;
  debeCambiarPassword?: boolean;
}

@Injectable({
  providedIn: 'root',
})
export class Auth {
  private readonly apiUrl = '/api/auth';

  constructor(
    private http: HttpClient,
    private tokenService: Token
  ) {}

  login(data: LoginRequest): Observable<LoginResponse> {
    return this.http.post<LoginResponse>(`${this.apiUrl}/login`, data).pipe(
      tap(response => {
      this.tokenService.guardarSesion(
        response.token,
        response.rol,
        response.codigoUsuario,
        Boolean(response.debeCambiarPassword)
      );
      })
    );
  }

  logout(): void {
    this.tokenService.limpiarSesion();
  }

  estaAutenticado(): boolean {
    return this.tokenService.estaAutenticado();
  }

  getRol(): string | null {
    return this.tokenService.getRol();
  }
}
