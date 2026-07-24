import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface PagoResponse {
  id: number;
  idRecibo: number;
  codigoRecibo: string;
  metodoPago: string;
  codigoOperacion: string;
  comprobanteUrl?: string;
  monto: number;
  estadoPago: string;
  fechaPago: string;
}

@Injectable({
  providedIn: 'root',
})
export class Pago {
  private readonly apiUrl = '/api/pagos';

  constructor(private http: HttpClient) {}

  listarPagos(
    estado?: string,
    params?: {
      anio?: number | '';
      mes?: number | '';
      buscar?: string;
      limit?: number;
    }
  ): Observable<PagoResponse[]> {
    let httpParams = new HttpParams();

    if (estado && estado !== 'TODOS') httpParams = httpParams.set('estado', estado);
    if (params?.anio) httpParams = httpParams.set('anio', String(params.anio));
    if (params?.mes) httpParams = httpParams.set('mes', String(params.mes));
    if (params?.buscar?.trim()) httpParams = httpParams.set('buscar', params.buscar.trim());
    if (params?.limit) httpParams = httpParams.set('limit', String(params.limit));

    return this.http.get<PagoResponse[]>(this.apiUrl, { params: httpParams });
  }

  buscarPorSuministro(codigoSuministro: string): Observable<PagoResponse[]> {
    return this.http.get<PagoResponse[]>(`${this.apiUrl}/suministro/${codigoSuministro}`);
  }

  aprobarPago(id: number): Observable<PagoResponse> {
    return this.http.patch<PagoResponse>(
      `${this.apiUrl}/${id}/aprobar`,
      {}
    );
  }

  rechazarPago(id: number): Observable<PagoResponse> {
    return this.http.patch<PagoResponse>(
      `${this.apiUrl}/${id}/rechazar`,
      {}
    );
  }

  listarPagosEnRevision(): Observable<PagoResponse[]> {
    return this.http.get<PagoResponse[]>(
      `${this.apiUrl}/revision`
    );
  }
}
