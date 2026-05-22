import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface SuministroLecturadorResponse {
  id: number;
  codigoSuministro: string;
  nombreSector: string;
  direccionSuministro: string;
  referencia: string;
  aliasSuministro: string;
  lecturaInicial: number;
  estado: boolean;
  nombreCliente?: string;
  dniCliente?: string;
}

export interface LecturaRequest {
  codigoSuministro: string;
  anio: number;
  mes: number;
  lecturaActual: number;
  observacion: string;
}

export interface ReciboGeneradoResponse {
  id: number;
  codigoRecibo: string;
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

export interface LecturaResponse {
  id: number;
  codigoSuministro: string;
  direccionSuministro: string;
  anio: number;
  mes: number;
  lecturaAnterior: number;
  lecturaActual: number;
  consumoM3: number;
  fechaLectura: string;
  observacion: string;
  recibo: ReciboGeneradoResponse;
}

@Injectable({
  providedIn: 'root',
})
export class Lecturador {
  private readonly apiLecturador = 'http://localhost:8080/api/lecturador';
  private readonly apiLecturas = 'http://localhost:8080/api/lecturas';

  constructor(private http: HttpClient) {}

  buscarSuministro(codigoSuministro: string): Observable<SuministroLecturadorResponse> {
    return this.http.get<SuministroLecturadorResponse>(
      `${this.apiLecturador}/suministros/${codigoSuministro}`
    );
  }

  registrarLectura(data: LecturaRequest): Observable<LecturaResponse> {
    return this.http.post<LecturaResponse>(this.apiLecturas, data);
  }
}