export function imprimirReciboJass(recibo: any, historialBase: any[] = []): void {
  const ventana = window.open('', '_blank', 'width=900,height=950');

  if (!ventana) {
    alert('El navegador bloqueÃ³ la ventana de impresiÃ³n.');
    return;
  }

  ventana.document.open();
  ventana.document.write(generarHtmlReciboCompacto(recibo, historialBase));
  ventana.document.close();
}

function generarHtmlReciboCompacto(recibo: any, historialBase: any[] = []): string {
  const subtotalAgua = numero(recibo.subtotalAgua || recibo.totalAgua || 0);
  const mantenimiento = numero(recibo.cargoMantenimiento || 0);
  const lector = numero(recibo.cargoLector || 0);
  const otros = numero(recibo.cargoOtros || 0);
  const mora = numero(recibo.mora || 0);
  const total = numero(recibo.total || recibo.totalRecibo || 0);
  const cargos = mantenimiento + lector + otros + mora;

  const cambioMedidor = Boolean(recibo.cambioMedidor);
  const consumoInusual = Boolean(recibo.consumoInusual);
  const lecturaInicialNuevoMedidor = recibo.lecturaInicialNuevoMedidor !== null &&
    recibo.lecturaInicialNuevoMedidor !== undefined
      ? numero(recibo.lecturaInicialNuevoMedidor)
      : null;

  const observacionCambioMedidor = texto(recibo.observacionCambioMedidor || '');
  const avisoLecturaHtml = generarAvisoLecturaHtml(
    cambioMedidor,
    consumoInusual,
    lecturaInicialNuevoMedidor,
    observacionCambioMedidor
  );

  const codigoRecibo = texto(recibo.codigoRecibo || '-');
  const codigoSuministro = texto(recibo.codigoSuministro || '-');

  const codigoValidacion = texto(recibo.codigoBarras || `${codigoRecibo}-${codigoSuministro}`);

  const cliente = texto(recibo.nombreCliente || recibo.cliente || 'No disponible');
  const dni = texto(recibo.dniCliente || '-');
  const direccion = texto(recibo.direccionSuministro || recibo.aliasSuministro || '-');
  const sector = texto(recibo.sector || '-');

  const periodoTexto = `${nombreMes(Number(recibo.mes))} ${recibo.anio || ''}`;

  const codigoBarrasSvg = generarCodigoBarrasSvg(codigoValidacion);
  const graficoSvg = generarGraficoConsumoSvgCompacto(recibo, historialBase);

  return `
    <!DOCTYPE html>
    <html lang="es">
    <head>
      <meta charset="UTF-8">
      <title>Recibo ${textoSeguro(codigoRecibo)}</title>

      <style>
        @page {
          size: A4;
          margin: 6mm;
        }

        * {
          box-sizing: border-box;
          -webkit-print-color-adjust: exact;
          print-color-adjust: exact;
        }

        html,
        body {
          margin: 0;
          padding: 0;
          background: #ffffff;
          font-family: Arial, Helvetica, sans-serif;
          color: #0f2f3d;
        }

        body {
          padding: 6px;
        }

        .receipt {
          width: 190mm;
          margin: 0 auto;
          border: 2px solid #1686a3;
          padding: 9px 11px;
          background: #ffffff;
          page-break-inside: avoid;
          break-inside: avoid;
        }

        .top {
          display: grid;
          grid-template-columns: 1fr 162px;
          gap: 10px;
          align-items: center;
          margin-bottom: 7px;
        }

        .brand {
          display: flex;
          align-items: center;
          gap: 9px;
        }

        .logo {
          width: 42px;
          height: 42px;
          border: 1px solid #b7d8e3;
          border-radius: 8px;
          display: grid;
          place-items: center;
          font-size: 24px;
        }

        .brand h1 {
          margin: 0;
          color: #1384a0;
          font-size: 23px;
          letter-spacing: 3px;
          font-weight: 900;
          line-height: 1;
        }

        .brand p {
          margin: 2px 0 0;
          font-size: 10px;
          font-weight: 700;
        }

        .period {
          border: 1px solid #d8d0b5;
          padding: 7px;
          text-align: center;
        }

        .period span {
          display: block;
          font-weight: 900;
          font-size: 10px;
        }

        .period strong {
          display: block;
          margin-top: 4px;
          font-size: 16px;
        }

        .line {
          height: 1.5px;
          background: #b7d8e3;
          margin: 6px 0 8px;
        }

        .info-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 8px;
          margin-bottom: 8px;
        }

        .box {
          border: 1px solid #b7d8e3;
          padding: 7px;
          min-height: 86px;
        }

        .box h3 {
          margin: 0 0 5px;
          font-size: 12.5px;
        }

        .row {
          display: grid;
          grid-template-columns: 78px 1fr;
          gap: 5px;
          margin: 3px 0;
          font-size: 10.4px;
          line-height: 1.15;
        }

        .row span {
          font-weight: 900;
        }

        .chart-title {
          text-align: center;
          font-weight: 900;
          font-size: 10px;
          margin-bottom: 1px;
        }

        .summary-row {
          display: grid;
          grid-template-columns: 1fr 1fr 1.2fr 1fr 1fr;
          border: 1px solid #b7d8e3;
          margin-bottom: 7px;
        }

        .summary-cell {
          padding: 6px;
          border-right: 1px solid #b7d8e3;
          min-height: 43px;
        }

        .summary-cell:last-child {
          border-right: none;
        }

        .summary-cell span {
          display: block;
          font-weight: 900;
          font-size: 10px;
          margin-bottom: 3px;
        }

        .summary-cell strong {
          font-size: 10.7px;
          line-height: 1.1;
        }

        table {
          width: 100%;
          border-collapse: collapse;
          margin-bottom: 7px;
        }

        th {
          text-align: left;
          padding: 5px 6px;
          border: 1px solid #b7d8e3;
          font-size: 10px;
          background: #f8fcfd;
        }

        td {
          padding: 5px 6px;
          border: 1px solid #b7d8e3;
          font-size: 10px;
          line-height: 1.12;
        }

        td.amount {
          text-align: right;
          font-weight: 900;
          white-space: nowrap;
        }

        .bottom {
          display: grid;
          grid-template-columns: 1.25fr 0.85fr;
          gap: 8px;
          align-items: start;
        }

        .notice {
          border: 1px solid #b7d8e3;
          padding: 7px;
          min-height: 60px;
          font-size: 9.7px;
          line-height: 1.22;
        }

        .notice strong {
          display: block;
          margin-bottom: 3px;
        }

        .reading-note {
          border: 1px solid #f4b183;
          background: #fff7ed;
          color: #7c2d12;
          padding: 6px 7px;
          margin-bottom: 7px;
          font-size: 9.5px;
          line-height: 1.25;
        }

        .reading-note strong {
          display: block;
          margin-bottom: 3px;
        }

        .barcode-box {
          border: 1px solid #b7d8e3;
          margin-top: 7px;
          height: 52px;
          display: grid;
          place-items: center;
          background: #ffffff;
          overflow: hidden;
        }

        .barcode-box svg {
          width: 98%;
          height: 45px;
        }

        .code {
          text-align: center;
          font-weight: 900;
          margin: 4px 0 0;
          font-size: 9.8px;
        }

        .total-panel {
          border: 2px solid #1686a3;
        }

        .total-row {
          display: grid;
          grid-template-columns: 1fr 1fr;
          border-bottom: 1px solid #b7d8e3;
        }

        .total-row:last-child {
          border-bottom: none;
        }

        .total-row span {
          padding: 7px;
          font-weight: 900;
          font-size: 10.5px;
        }

        .total-row strong {
          padding: 7px;
          text-align: right;
          font-size: 10.5px;
        }

        .grand strong {
          font-size: 21px;
          line-height: 1;
        }

        .footer {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 8px;
          margin-top: 7px;
        }

        .footer div {
          border: 1px solid #b7d8e3;
          padding: 6px;
          font-size: 9px;
          line-height: 1.15;
        }

        .actions {
          width: 190mm;
          margin: 10px auto 0;
          display: flex;
          justify-content: flex-end;
          gap: 8px;
        }

        button {
          border: none;
          border-radius: 8px;
          padding: 10px 14px;
          font-weight: 900;
          cursor: pointer;
        }

        .print {
          background: #1686a3;
          color: white;
        }

        .close {
          background: #e2e8f0;
          color: #0f2f3d;
        }

        @media print {
          body {
            padding: 0;
          }

          .receipt {
            width: 190mm;
            page-break-inside: avoid;
            break-inside: avoid;
          }

          .actions {
            display: none;
          }
        }
      </style>
    </head>

    <body>
      <div class="receipt">
        <div class="top">
          <div class="brand">
            <div class="logo">ðŸ’§</div>

            <div>
              <h1>AGUA POTABLE HUACARIZ</h1>
              <p>Servicio de agua potable Â· Recibo de cobranza</p>
              <p>Cajamarca, PerÃº Â· Sistema de GestiÃ³n de Agua</p>
            </div>
          </div>

          <div class="period">
            <span>PERIODO DE FACTURACIÃ“N</span>
            <strong>${textoSeguro(periodoTexto)}</strong>
          </div>
        </div>

        <div class="line"></div>

        <div class="info-grid">
          <div class="box">
            <h3>Datos del servicio</h3>
            <div class="row"><span>Cliente:</span><strong>${textoSeguro(cliente)}</strong></div>
            <div class="row"><span>DNI:</span><strong>${textoSeguro(dni)}</strong></div>
            <div class="row"><span>Recibo:</span><strong>${textoSeguro(codigoRecibo)}</strong></div>
            <div class="row"><span>Suministro:</span><strong>${textoSeguro(codigoSuministro)}</strong></div>
            <div class="row"><span>DirecciÃ³n:</span><strong>${textoSeguro(direccion)}</strong></div>
            <div class="row"><span>Sector:</span><strong>${textoSeguro(sector)}</strong></div>
            <div class="row"><span>Estado:</span><strong>${textoSeguro(recibo.estadoRecibo || 'PENDIENTE')}</strong></div>
          </div>

          <div class="box">
            <div class="chart-title">Historial grÃ¡fico de consumo Ãºltimos 3 meses</div>
            ${graficoSvg}
          </div>
        </div>

        <div class="summary-row">
          <div class="summary-cell">
            <span>Periodo</span>
            <strong>${textoSeguro(periodoTexto)}</strong>
          </div>

          <div class="summary-cell">
            <span>Consumo</span>
            <strong>${numero(recibo.consumoM3 || 0).toFixed(3)} mÂ³</strong>
          </div>

          <div class="summary-cell">
            <span>EmisiÃ³n</span>
            <strong>${textoSeguro(formatearFecha(recibo.fechaEmision))}</strong>
          </div>

          <div class="summary-cell">
            <span>Vencimiento</span>
            <strong>${textoSeguro(formatearFechaSimple(recibo.fechaVencimiento))}</strong>
          </div>

          <div class="summary-cell">
            <span>Total</span>
            <strong>S/ ${total.toFixed(2)}</strong>
          </div>
        </div>

        ${avisoLecturaHtml}

        <table>
          <thead>
            <tr>
              <th>Concepto</th>
              <th>DescripciÃ³n</th>
              <th>Importe</th>
            </tr>
          </thead>

          <tbody>
            <tr>
              <td>Consumo de agua</td>
              <td>Consumo registrado: ${numero(recibo.consumoM3 || 0).toFixed(3)} mÂ³</td>
              <td class="amount">S/ ${subtotalAgua.toFixed(2)}</td>
            </tr>

            <tr>
              <td>Mantenimiento</td>
              <td>Cargo de mantenimiento del sistema</td>
              <td class="amount">S/ ${mantenimiento.toFixed(2)}</td>
            </tr>

            <tr>
              <td>Lector</td>
              <td>Cargo por registro de lectura</td>
              <td class="amount">S/ ${lector.toFixed(2)}</td>
            </tr>

            <tr>
              <td>Otros cargos</td>
              <td>Otros cargos administrativos o adicionales</td>
              <td class="amount">S/ ${otros.toFixed(2)}</td>
            </tr>

            <tr>
              <td>Mora</td>
              <td>Cargo por vencimiento, si corresponde</td>
              <td class="amount">S/ ${mora.toFixed(2)}</td>
            </tr>
          </tbody>
        </table>

        <div class="bottom">
          <div>
            <div class="notice">
              <strong>Estimado usuario:</strong>
              Cumpla con realizar sus pagos antes de la fecha de vencimiento para evitar mora,
              suspensiÃ³n del servicio o restricciones administrativas. Conserve este recibo como constancia de cobranza.
            </div>

            <div class="barcode-box">
              ${codigoBarrasSvg}
            </div>

            <div class="code">
              ${textoSeguro(codigoValidacion)}
            </div>
          </div>

          <div class="total-panel">
            <div class="total-row">
              <span>Subtotal agua</span>
              <strong>S/ ${subtotalAgua.toFixed(2)}</strong>
            </div>

            <div class="total-row">
              <span>Cargos</span>
              <strong>S/ ${cargos.toFixed(2)}</strong>
            </div>

            <div class="total-row grand">
              <span>Total a pagar</span>
              <strong>S/ ${total.toFixed(2)}</strong>
            </div>

            <div class="total-row">
              <span>Vence</span>
              <strong>${textoSeguro(formatearFechaSimple(recibo.fechaVencimiento))}</strong>
            </div>
          </div>
        </div>

        <div class="footer">
          <div>
            <strong>AtenciÃ³n:</strong> Documento emitido por el sistema de gestiÃ³n de agua Agua Potable Huacariz.
          </div>

          <div>
            <strong>ValidaciÃ³n:</strong> CÃ³digo de barras ${textoSeguro(codigoValidacion)}
          </div>
        </div>
      </div>

      <div class="actions">
        <button class="close" onclick="window.close()">Cerrar</button>
        <button class="print" onclick="window.print()">Imprimir / guardar PDF</button>
      </div>
    </body>
    </html>
  `;
}

  function generarAvisoLecturaHtml(
    cambioMedidor: boolean,
    consumoInusual: boolean,
    lecturaInicialNuevoMedidor: number | null,
    observacionCambioMedidor: string
  ): string {
    if (!cambioMedidor && !consumoInusual) {
      return '';
    }

    const partes: string[] = [];

    if (cambioMedidor) {
      partes.push(
        `Cambio de medidor. Lectura inicial del nuevo medidor: ${
          lecturaInicialNuevoMedidor !== null ? lecturaInicialNuevoMedidor.toFixed(3) : '0.000'
        } m³.`
      );

      if (observacionCambioMedidor) {
        partes.push(`Motivo: ${textoSeguro(observacionCambioMedidor)}.`);
      }

      partes.push('El código del suministro se mantiene igual.');
    }

    if (consumoInusual) {
      partes.push('Consumo inusual detectado. Se recomienda verificar la lectura registrada.');
    }

    return `
      <div class="reading-note">
        <strong>Observación de lectura:</strong>
        ${partes.map((item) => `<div>${item}</div>`).join('')}
      </div>
    `;
  }

function generarGraficoConsumoSvgCompacto(reciboActual: any, historialBase: any[]): string {
  const codigo = texto(reciboActual.codigoSuministro || '').toUpperCase();
  const periodoActual = numero(reciboActual.anio) * 100 + numero(reciboActual.mes);

  let historial = (historialBase || [])
    .filter((item: any) => texto(item.codigoSuministro || '').toUpperCase() === codigo)
    .filter((item: any) => (numero(item.anio) * 100 + numero(item.mes)) <= periodoActual)
    .sort((a: any, b: any) => {
      const periodoA = numero(a.anio) * 100 + numero(a.mes);
      const periodoB = numero(b.anio) * 100 + numero(b.mes);
      return periodoB - periodoA;
    })
    .slice(0, 3)
    .reverse();

  if (!historial.length) {
    historial = [reciboActual];
  }

  const maximo = Math.max(...historial.map((item: any) => numero(item.consumoM3 || 0)), 1);

  const barras = historial.map((item: any, index: number) => {
    const consumo = numero(item.consumoM3 || 0);
    const alto = Math.max((consumo / maximo) * 44, 3);
    const x = 34 + index * 72;
    const y = 57 - alto;
    const etiqueta = `${nombreMes(numero(item.mes)).substring(0, 3)} ${texto(item.anio).substring(2)}`;

    return `
      <rect x="${x}" y="${y}" width="28" height="${alto}" rx="3" fill="#1686a3"></rect>
      <text x="${x + 14}" y="72" text-anchor="middle" font-size="8.5" fill="#0f2f3d">${textoSeguro(etiqueta)}</text>
      <text x="${x + 14}" y="${y - 4}" text-anchor="middle" font-size="8.5" font-weight="700" fill="#0f2f3d">${consumo.toFixed(1)}</text>
    `;
  }).join('');

  return `
    <svg viewBox="0 0 245 82" width="100%" height="70" xmlns="http://www.w3.org/2000/svg">
      <line x1="18" y1="60" x2="230" y2="60" stroke="#7aaebe" stroke-width="1.5"></line>
      ${barras}
    </svg>
  `;
}

function generarCodigoBarrasSvg(valor: string): string {
  const textoCodigo = texto(valor || 'RECIBO-JASS');
  let x = 8;
  let barras = '';

  for (let i = 0; i < textoCodigo.length; i++) {
    const code = textoCodigo.charCodeAt(i);

    for (let bit = 0; bit < 7; bit++) {
      const activo = ((code + bit) % 3) !== 0;
      const ancho = ((code >> bit) & 1) ? 2 : 1;

      if (activo) {
        barras += `<rect x="${x}" y="4" width="${ancho}" height="36" fill="#0f2f3d"></rect>`;
      }

      x += ancho + 1;
    }

    x += 1;
  }

  const anchoTotal = Math.max(x + 8, 260);

  return `
    <svg viewBox="0 0 ${anchoTotal} 48" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="none">
      <rect x="0" y="0" width="${anchoTotal}" height="48" fill="#ffffff"></rect>
      ${barras}
      <text x="${anchoTotal / 2}" y="46" text-anchor="middle" font-size="7" fill="#0f2f3d">
        ${textoSeguro(textoCodigo)}
      </text>
    </svg>
  `;
}

function nombreMes(mes: number): string {
  const meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  return meses[mes - 1] || 'Mes invÃ¡lido';
}

function formatearFecha(fecha: string): string {
  if (!fecha || fecha === '-') {
    return '-';
  }

  const date = new Date(fecha);

  if (Number.isNaN(date.getTime())) {
    return texto(fecha).substring(0, 10);
  }

  return date.toLocaleDateString('es-PE');
}

function formatearFechaSimple(fecha: string): string {
  if (!fecha || fecha === '-') {
    return '-';
  }

  return texto(fecha).substring(0, 10);
}

function numero(value: unknown): number {
  const n = Number(value);
  return Number.isFinite(n) ? n : 0;
}

function texto(value: unknown): string {
  return String(value ?? '');
}

function textoSeguro(value: unknown): string {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}
