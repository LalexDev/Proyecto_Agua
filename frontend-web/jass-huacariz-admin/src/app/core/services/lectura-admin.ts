import { HttpClient, HttpParams } from '@angular/common/http';
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
  cambioMedidor?: boolean;
  lecturaInicialNuevoMedidor?: number | null;
  observacionCambioMedidor?: string | null;
  consumoInusual?: boolean;
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

  listarHistorial(params?: {
    anio?: number | '';
    mes?: number | '';
    buscar?: string;
    limit?: number;
  }): Observable<HistorialLectura[]> {
    let httpParams = new HttpParams();

    if (params?.anio) httpParams = httpParams.set('anio', String(params.anio));
    if (params?.mes) httpParams = httpParams.set('mes', String(params.mes));
    if (params?.buscar?.trim()) httpParams = httpParams.set('buscar', params.buscar.trim());
    if (params?.limit) httpParams = httpParams.set('limit', String(params.limit));

    return this.http.get<HistorialLectura[]>(`${this.apiUrl}/historial`, { params: httpParams });
  }

  listarPendientesLectura(
    anio: number,
    mes: number,
    buscar?: string,
    limit?: number
  ): Observable<LecturaPendiente[]> {
    let params = new HttpParams()
      .set('anio', String(anio))
      .set('mes', String(mes));

    if (buscar?.trim()) params = params.set('buscar', buscar.trim());
    if (limit) params = params.set('limit', String(limit));

    return this.http.get<LecturaPendiente[]>(`${this.apiUrl}/pendientes`, { params });
  }
}


