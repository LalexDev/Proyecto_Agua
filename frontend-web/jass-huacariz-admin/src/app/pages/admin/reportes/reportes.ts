import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';

interface ReporteMensual {
  periodo: string;
  clientesActivos: number;
  recibosGenerados: number;
  recibosPagados: number;
  recibosPendientes: number;
  recibosVencidos: number;
  consumoTotalM3: number;
  montoRecaudado: number;
  montoPendiente: number;
}

@Component({
  selector: 'app-reportes',
  imports: [FormsModule],
  templateUrl: './reportes.html',
  styleUrl: './reportes.scss'
})
export class Reportes {
  periodoSeleccionado = 'Mayo 2026';

  reportes: ReporteMensual[] = [
    {
      periodo: 'Marzo 2026',
      clientesActivos: 108,
      recibosGenerados: 115,
      recibosPagados: 98,
      recibosPendientes: 12,
      recibosVencidos: 5,
      consumoTotalM3: 1450.5,
      montoRecaudado: 4890,
      montoPendiente: 620
    },
    {
      periodo: 'Abril 2026',
      clientesActivos: 115,
      recibosGenerados: 121,
      recibosPagados: 104,
      recibosPendientes: 13,
      recibosVencidos: 4,
      consumoTotalM3: 1585.75,
      montoRecaudado: 5320,
      montoPendiente: 710
    },
    {
      periodo: 'Mayo 2026',
      clientesActivos: 128,
      recibosGenerados: 136,
      recibosPagados: 102,
      recibosPendientes: 28,
      recibosVencidos: 6,
      consumoTotalM3: 1720.35,
      montoRecaudado: 6125,
      montoPendiente: 980
    }
  ];

  get reporteActual(): ReporteMensual {
    return this.reportes.find(reporte => reporte.periodo === this.periodoSeleccionado) || this.reportes[0];
  }

  get porcentajePagados(): number {
    return this.calcularPorcentaje(this.reporteActual.recibosPagados, this.reporteActual.recibosGenerados);
  }

  get porcentajePendientes(): number {
    return this.calcularPorcentaje(this.reporteActual.recibosPendientes, this.reporteActual.recibosGenerados);
  }

  get porcentajeVencidos(): number {
    return this.calcularPorcentaje(this.reporteActual.recibosVencidos, this.reporteActual.recibosGenerados);
  }

  get maxRecaudacion(): number {
    return Math.max(...this.reportes.map(reporte => reporte.montoRecaudado));
  }

  obtenerAltoBarra(monto: number): number {
    return Math.round((monto / this.maxRecaudacion) * 100);
  }

  private calcularPorcentaje(valor: number, total: number): number {
    if (total === 0) {
      return 0;
    }

    return Math.round((valor / total) * 100);
  }
}