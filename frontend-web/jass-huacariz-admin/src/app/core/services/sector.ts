import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface SectorResponse {
  id: number;
  nombre: string;
  descripcion: string;
  estado: boolean;
}

@Injectable({
  providedIn: 'root',
})
export class Sector {
  private readonly apiUrl = 'http://localhost:8080/api/sectores';

  constructor(private http: HttpClient) {}

  listarSectores(): Observable<SectorResponse[]> {
    return this.http.get<SectorResponse[]>(this.apiUrl);
  }
}