import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface ClientePerfilResponse {
  idCliente: number;
  codigoUsuario: string;
  dni: string;
  nombres: string;
  apellidos: string;
  telefono: string;
  correo: string;
  estado: boolean;
}

export interface SuministroClienteResponse {
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

export interface ReciboClienteResponse {
  id: number;
  codigoRecibo: string;
  codigoSuministro: string;
  direccionSuministro: string;
  anio: number;
  mes: number;
  consumoM3: number;
  subtotalAgua: number;
  cargoMantenimiento: number;
  cargoLector: number;
  mora: number;
  total: number;
  estadoRecibo: string;
  fechaEmision: string;
  fechaVencimiento: string;
}

export interface PagoClienteRequest {
  metodoPago: string;
  codigoOperacion: string;
}

export interface PagoClienteResponse {
  id: number;
  idRecibo: number;
  codigoRecibo: string;
  metodoPago: string;
  codigoOperacion: string;
  monto: number;
  estadoPago: string;
  fechaPago: string;
}

export interface CambiarPasswordRequest {
  passwordActual: string;
  nuevaPassword: string;
  confirmarPassword: string;
}

export interface CambiarPasswordResponse {
  mensaje: string;
}

@Injectable({
  providedIn: 'root',
})
export class ClientePortal {
  private readonly apiUrl = 'http://localhost:8080/api/cliente';

  constructor(private http: HttpClient) {}

  obtenerMiPerfil(): Observable<ClientePerfilResponse> {
    return this.http.get<ClientePerfilResponse>(`${this.apiUrl}/me`);
  }

  listarMisSuministros(): Observable<SuministroClienteResponse[]> {
    return this.http.get<SuministroClienteResponse[]>(`${this.apiUrl}/me/suministros`);
  }

  listarMisRecibos(): Observable<ReciboClienteResponse[]> {
    return this.http.get<ReciboClienteResponse[]>(`${this.apiUrl}/me/recibos`);
  }

  pagarMiRecibo(idRecibo: number, data: PagoClienteRequest): Observable<PagoClienteResponse> {
    return this.http.patch<PagoClienteResponse>(`${this.apiUrl}/me/recibos/${idRecibo}/pagar`, data);
  }

  cambiarMiPassword(data: CambiarPasswordRequest): Observable<CambiarPasswordResponse> {
    return this.http.patch<CambiarPasswordResponse>(`${this.apiUrl}/me/password`, data);
  }
}