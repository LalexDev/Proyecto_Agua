import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
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

  cambioMedidor?: boolean;
  lecturaInicialNuevoMedidor?: number | null;
  observacionCambioMedidor?: string | null;
  consumoInusual?: boolean;

  subtotalAgua: number;
  cargoMantenimiento: number;
  cargoLector: number;
  cargoOtros: number;
  mora: number;
  total: number;

  estadoRecibo: string;
  fechaEmision: string;
  fechaVencimiento: string;

  telefonoCliente?: string;
  telefono?: string;
  celularCliente?: string;
  celular?: string;


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
  private readonly apiUrl = '/api/recibos';

  constructor(private http: HttpClient) {}

  listarRecibos(params?: {
    anio?: number | '';
    mes?: number | '';
    estado?: string;
    buscar?: string;
    limit?: number;
  }): Observable<ReciboResponse[]> {
    let httpParams = new HttpParams();

    if (params?.anio) httpParams = httpParams.set('anio', String(params.anio));
    if (params?.mes) httpParams = httpParams.set('mes', String(params.mes));
    if (params?.estado && params.estado !== 'TODOS') httpParams = httpParams.set('estado', params.estado);
    if (params?.buscar?.trim()) httpParams = httpParams.set('buscar', params.buscar.trim());
    if (params?.limit) httpParams = httpParams.set('limit', String(params.limit));

    return this.http.get<ReciboResponse[]>(this.apiUrl, { params: httpParams });
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
