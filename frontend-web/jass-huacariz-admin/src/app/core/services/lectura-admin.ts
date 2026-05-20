import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

export interface HistorialLectura {
  idLectura: number;
  codigoSuministro: string;
  aliasSuministro: string;
  direccionSuministro: string;
  cliente: string;
  dniCliente: string;
  sector: string;
  anio: number;
  mes: number;
  lecturaAnterior: number;
  lecturaActual: number;
  consumoM3: number;
  codigoRecibo: string;
  totalRecibo: number;
  estadoRecibo: string;
  fechaRegistro: string;
}

@Injectable({
  providedIn: 'root'
})
export class LecturaAdmin {
  private readonly apiUrl = 'http://localhost:8080/api/admin/lecturas';

  constructor(private http: HttpClient) {}

  listarHistorial(): Observable<HistorialLectura[]> {
    return this.http.get<HistorialLectura[]>(`${this.apiUrl}/historial`);
  }
}