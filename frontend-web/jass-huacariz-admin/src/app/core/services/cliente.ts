
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export type EstadoInstalacionSuministro = 'INSTALADO' | 'PENDIENTE_INSTALACION';

export interface SuministroResponse {
  id: number;
  codigoSuministro: string;
  idSector: number;
  nombreSector: string;
  direccionSuministro: string;
  referencia: string;
  aliasSuministro: string;
  lecturaInicial: number;
  estado: boolean;
  estadoInstalacion?: string;
}

export interface ClienteResponse {
  id: number;
  dni: string;
  nombres: string;
  apellidos: string;
  telefono: string;
  correo: string;
  estado: boolean;
  codigoUsuario: string;
  passwordInicial: string;
  suministros: SuministroResponse[];
}

export interface SuministroRequest {
  idSector: number;
  direccionSuministro: string;
  referencia: string;
  aliasSuministro: string;
  lecturaInicial: number;
}

export interface ClienteRequest {
  dni: string;
  nombres: string;
  apellidos: string;
  telefono: string;
  correo: string;
  estado: boolean;
  suministros: SuministroRequest[];
}

export interface LecturadorRequest {
  dni: string;
  nombres: string;
  apellidos: string;
  telefono: string;
  correo: string;
  codigoUsuario: string;
  password: string;
  estado: boolean;
  sectorAsignado?: string;
}

export interface LecturadorResponse {
  id: number;
  dni: string;
  nombres: string;
  apellidos: string;
  telefono: string;
  correo: string;
  codigoUsuario: string;
  estado: boolean;
  rol: string;
  sectorAsignado?: string;
  passwordInicial?: string;
}

@Injectable({
  providedIn: 'root',
})
export class Cliente {
  private readonly apiUrl = 'http://localhost:8080/api/clientes';
  private readonly usuariosUrl = 'http://localhost:8080/api/usuarios';

  constructor(private http: HttpClient) {}

  listarClientes(): Observable<ClienteResponse[]> {
    return this.http.get<ClienteResponse[]>(this.apiUrl);
  }

  registrarCliente(data: ClienteRequest): Observable<ClienteResponse> {
    return this.http.post<ClienteResponse>(this.apiUrl, data);
  }

  actualizarCliente(id: number, data: ClienteRequest): Observable<ClienteResponse> {
    return this.http.put<ClienteResponse>(`${this.apiUrl}/${id}`, data);
  }

  obtenerClientePorId(id: number): Observable<ClienteResponse> {
    return this.http.get<ClienteResponse>(`${this.apiUrl}/${id}`);
  }

  listarSuministrosPorCliente(id: number): Observable<SuministroResponse[]> {
    return this.http.get<SuministroResponse[]>(`${this.apiUrl}/${id}/suministros`);
  }

  agregarSuministro(clienteId: number, data: SuministroRequest): Observable<SuministroResponse> {
    return this.http.post<SuministroResponse>(`${this.apiUrl}/${clienteId}/suministros`, data);
  }

  actualizarSuministro(
    clienteId: number,
    suministroId: number,
    data: SuministroRequest
  ): Observable<SuministroResponse> {
    return this.http.put<SuministroResponse>(
      `${this.apiUrl}/${clienteId}/suministros/${suministroId}`,
      data
    );
  }

  eliminarSuministro(clienteId: number, suministroId: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${clienteId}/suministros/${suministroId}`);
  }

  cambiarEstadoCliente(id: number, estado: boolean): Observable<ClienteResponse> {
    return this.http.patch<ClienteResponse>(`${this.apiUrl}/${id}/estado?estado=${estado}`, {});
  }

  cambiarEstadoSuministro(
    clienteId: number,
    suministroId: number,
    estado: boolean
  ): Observable<SuministroResponse> {
    return this.http.patch<SuministroResponse>(
      `${this.apiUrl}/${clienteId}/suministros/${suministroId}/estado?estado=${estado}`,
      {}
    );
  }

  cambiarEstadoInstalacionSuministro(
    clienteId: number,
    suministroId: number,
    estadoInstalacion: EstadoInstalacionSuministro
  ): Observable<SuministroResponse> {
    return this.http.patch<SuministroResponse>(
      `${this.apiUrl}/${clienteId}/suministros/${suministroId}/estado-instalacion?estadoInstalacion=${estadoInstalacion}`,
      {}
    );
  }

  listarLecturadores(): Observable<LecturadorResponse[]> {
    return this.http.get<LecturadorResponse[]>(`${this.usuariosUrl}/lecturadores`);
  }

  registrarLecturador(data: LecturadorRequest): Observable<LecturadorResponse> {
    return this.http.post<LecturadorResponse>(`${this.usuariosUrl}/lecturadores`, data);
  }

  actualizarLecturador(id: number, data: LecturadorRequest): Observable<LecturadorResponse> {
    return this.http.put<LecturadorResponse>(`${this.usuariosUrl}/lecturadores/${id}`, data);
  }

  cambiarEstadoLecturador(id: number, estado: boolean): Observable<LecturadorResponse> {
    return this.http.patch<LecturadorResponse>(
      `${this.usuariosUrl}/lecturadores/${id}/estado?estado=${estado}`,
      {}
    );
  }

  eliminarLecturador(id: number): Observable<void> {
    return this.http.delete<void>(`${this.usuariosUrl}/lecturadores/${id}`);
  }
}