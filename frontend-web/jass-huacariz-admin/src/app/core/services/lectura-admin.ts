import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

export interface HistorialLectura {
  idLectura: number;
  codigoSuministro: string;
  aliasSuministro: string;
  direccionSuministro: string;
  cliente: string;
  nombreCliente?: string;
  dniCliente: string;
  sector: string;
  anio: number;
  mes: number;
  lecturaAnterior: number;
  lecturaActual: number;
  consumoM3: number;
  codigoRecibo: string;
  totalRecibo: number;
  total?: number;
  subtotalAgua?: number;
  totalAgua?: number;
  cargoMantenimiento?: number;
  cargoLector?: number;
  cargoOtros?: number;
  mora?: number;
  estadoRecibo: string;
  fechaRegistro: string;
  fechaLectura?: string;
  fechaEmision?: string;
  fechaVencimiento?: string;
  codigoBarras?: string;
}

export interface LecturaPendiente {
  idSuministro: number;
  codigoSuministro: string;
  nombreCliente: string;
  dniCliente: string;
  aliasSuministro: string;
  direccionSuministro: string;
  referencia: string;
  sector: string;
  estado: boolean;
  estadoInstalacion: string;
  anio: number;
  mes: number;
  lecturaAnterior: number;
}

@Injectable({
  providedIn: 'root'
})
export class LecturaAdmin {
  private readonly apiUrl = '/api/admin/lecturas';

  constructor(private http: HttpClient) {}

  listarHistorial(): Observable<HistorialLectura[]> {
    return this.http.get<HistorialLectura[]>(`${this.apiUrl}/historial`);
  }

  listarPendientesLectura(anio: number, mes: number): Observable<LecturaPendiente[]> {
    return this.http.get<LecturaPendiente[]>(
      `${this.apiUrl}/pendientes?anio=${anio}&mes=${mes}`
    );
  }
}


