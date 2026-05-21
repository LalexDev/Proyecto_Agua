import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

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

@Injectable({
  providedIn: 'root',
})
export class Cliente {
  private readonly apiUrl = 'http://localhost:8080/api/clientes';

  constructor(private http: HttpClient) {}

  listarClientes(): Observable<ClienteResponse[]> {
    return this.http.get<ClienteResponse[]>(this.apiUrl);
  }

  registrarCliente(data: ClienteRequest): Observable<ClienteResponse> {
    return this.http.post<ClienteResponse>(this.apiUrl, data);
  }

  obtenerClientePorId(id: number): Observable<ClienteResponse> {
    return this.http.get<ClienteResponse>(`${this.apiUrl}/${id}`);
  }

  listarSuministrosPorCliente(id: number): Observable<SuministroResponse[]> {
    return this.http.get<SuministroResponse[]>(`${this.apiUrl}/${id}/suministros`);
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
}