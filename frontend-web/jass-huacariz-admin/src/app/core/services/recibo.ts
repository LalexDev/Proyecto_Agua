import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface ReciboResponse {
  id: number;
  codigoRecibo: string;
  codigoSuministro?: string;
  direccionSuministro?: string;
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

@Injectable({
  providedIn: 'root',
})
export class Recibo {
  private readonly apiUrl = 'http://localhost:8080/api/recibos';

  constructor(private http: HttpClient) {}

  listarRecibos(): Observable<ReciboResponse[]> {
    return this.http.get<ReciboResponse[]>(this.apiUrl);
  }

  listarPendientes(): Observable<ReciboResponse[]> {
    return this.http.get<ReciboResponse[]>(`${this.apiUrl}/pendientes`);
  }
}
