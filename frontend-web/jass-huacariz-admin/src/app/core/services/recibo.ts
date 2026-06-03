import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface ReciboResponse {
  id: number;
  codigoRecibo: string;

  codigoSuministro?: string;
  direccionSuministro?: string;
  aliasSuministro?: string;
  sector?: string;

  nombreCliente?: string;
  dniCliente?: string;

  anio: number;
  mes: number;

  consumoM3: number;
  subtotalAgua: number;
  cargoMantenimiento: number;
  cargoLector: number;
  cargoOtros: number;
  mora: number;
  total: number;

  estadoRecibo: string;
  fechaEmision: string;
  fechaVencimiento: string;

  codigoBarras?: string;
}

export interface PagoRequest {
  metodoPago: string;
  codigoOperacion: string;
}

export interface PagoResponse {
  id: number;
  idRecibo: number;
  codigoRecibo: string;
  metodoPago: string;
  codigoOperacion: string;
  monto: number;
  estadoPago: string;
  fechaPago: string;
}

@Injectable({
  providedIn: 'root',
})
export class Recibo {
  private readonly apiUrl = 'https://qnsdd0d9-8080.brs.devtunnels.ms/api/recibos';

  constructor(private http: HttpClient) {}

  listarRecibos(): Observable<ReciboResponse[]> {
    return this.http.get<ReciboResponse[]>(this.apiUrl);
  }

  listarPendientes(): Observable<ReciboResponse[]> {
    return this.http.get<ReciboResponse[]>(`${this.apiUrl}/pendientes`);
  }

  buscarPorSuministro(codigoSuministro: string): Observable<ReciboResponse[]> {
    return this.http.get<ReciboResponse[]>(`${this.apiUrl}/suministro/${codigoSuministro}`);
  }

  pagarRecibo(idRecibo: number, data: PagoRequest): Observable<PagoResponse> {
    return this.http.patch<PagoResponse>(`${this.apiUrl}/${idRecibo}/pagar`, data);
  }
}