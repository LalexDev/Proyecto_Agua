import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';
import * as QRCode from 'qrcode';

@Component({
  selector: 'app-qr-suministro',
  imports: [CommonModule, FormsModule],
  templateUrl: './qr-suministro.html',
  styleUrl: './qr-suministro.scss',
})
export class QrSuministro implements OnInit {
  codigoSuministro = '';
  aliasSuministro = '';
  direccionSuministro = '';
  nombreCliente = '';
  dniCliente = '';

  qrDataUrl = '';
  error = '';
  exito = '';

  constructor(private route: ActivatedRoute) {}

  ngOnInit(): void {
    this.route.queryParamMap.subscribe(params => {
      const codigo = params.get('codigo');
      const alias = params.get('alias');
      const direccion = params.get('direccion');
      const cliente = params.get('cliente');
      const dni = params.get('dni');

      if (codigo) {
        this.codigoSuministro = codigo.trim().toUpperCase();
        this.aliasSuministro = alias || '';
        this.direccionSuministro = direccion || '';
        this.nombreCliente = cliente || '';
        this.dniCliente = dni || '';
        this.generarQr();
      }
    });
  }

  async generarQr(): Promise<void> {
    this.error = '';
    this.exito = '';
    this.qrDataUrl = '';

    const codigo = this.codigoSuministro.trim().toUpperCase();

    if (!codigo) {
      this.error = 'Ingrese el cÃ³digo del suministro.';
      return;
    }

    try {
      this.codigoSuministro = codigo;

      this.qrDataUrl = await QRCode.toDataURL(codigo, {
        width: 420,
        margin: 2,
        errorCorrectionLevel: 'H',
        color: {
          dark: '#07384A',
          light: '#FFFFFF'
        }
      });

      this.exito = 'CÃ³digo QR generado correctamente.';
    } catch {
      this.error = 'No se pudo generar el cÃ³digo QR.';
    }
  }

  limpiar(): void {
    this.codigoSuministro = '';
    this.aliasSuministro = '';
    this.direccionSuministro = '';
    this.nombreCliente = '';
    this.dniCliente = '';
    this.qrDataUrl = '';
    this.error = '';
    this.exito = '';
  }

  async copiarCodigo(): Promise<void> {
    this.error = '';
    this.exito = '';

    const codigo = this.codigoSuministro.trim().toUpperCase();

    if (!codigo) {
      this.error = 'Primero ingrese o genere un cÃ³digo de suministro.';
      return;
    }

    try {
      await navigator.clipboard.writeText(codigo);
      this.exito = 'CÃ³digo copiado al portapapeles.';
    } catch {
      this.error = 'No se pudo copiar el cÃ³digo. Copia manualmente el cÃ³digo del suministro.';
    }
  }

  descargarQr(): void {
    this.error = '';
    this.exito = '';

    if (!this.qrDataUrl) {
      this.error = 'Primero genere el cÃ³digo QR.';
      return;
    }

    const codigo = this.codigoSuministro || 'suministro';
    const enlace = document.createElement('a');

    enlace.href = this.qrDataUrl;
    enlace.download = `qr_${codigo}.png`;
    enlace.click();

    this.exito = 'QR descargado correctamente.';
  }

  imprimirQr(): void {
    this.error = '';
    this.exito = '';

    if (!this.qrDataUrl) {
      this.error = 'Primero genere el cÃ³digo QR.';
      return;
    }

    const codigo = this.textoSeguro(this.codigoSuministro);
    const alias = this.textoSeguro(this.aliasSuministro || 'Suministro de agua');
    const direccion = this.textoSeguro(this.direccionSuministro || '-');
    const cliente = this.textoSeguro(this.nombreCliente || '-');
    const dni = this.textoSeguro(this.dniCliente || '-');

    const ventana = window.open('', '_blank', 'width=760,height=850');

    if (!ventana) {
      this.error = 'El navegador bloqueÃ³ la ventana de impresiÃ³n.';
      return;
    }

    const html = `
      <!DOCTYPE html>
      <html lang="es">
      <head>
        <meta charset="UTF-8">
        <title>QR Suministro ${codigo}</title>
        <style>
          * {
            box-sizing: border-box;
          }

          body {
            margin: 0;
            padding: 28px;
            font-family: Arial, sans-serif;
            background: #eef4f7;
            color: #0f2f44;
          }

          .sheet {
            max-width: 620px;
            margin: auto;
            background: #ffffff;
            border-radius: 24px;
            padding: 28px;
            border: 1px solid #dbe7ec;
            box-shadow: 0 18px 40px rgba(15, 23, 42, 0.08);
          }

          .brand {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 16px;
            padding-bottom: 18px;
            border-bottom: 1px solid #e8f1f6;
          }

          .brand-left {
            display: flex;
            align-items: center;
            gap: 14px;
          }

          .logo {
            width: 62px;
            height: 62px;
            border-radius: 18px;
            background: #1ba3c7;
            color: white;
            display: grid;
            place-items: center;
            font-size: 32px;
          }

          h1, h2, h3, p {
            margin: 0;
          }

          h1 {
            font-size: 25px;
            font-weight: 900;
            color: #0f2f44;
          }

          .subtitle {
            color: #64748b;
            margin-top: 4px;
            font-size: 13px;
            font-weight: 700;
          }

          .tag {
            display: inline-flex;
            padding: 8px 14px;
            border-radius: 999px;
            background: #e8f7fb;
            color: #1583a3;
            font-size: 12px;
            font-weight: 900;
          }

          .qr-section {
            margin-top: 22px;
            text-align: center;
            padding: 24px;
            border-radius: 24px;
            background: linear-gradient(135deg, #07384a, #1ba3c7);
            color: #ffffff;
          }

          .qr-box {
            width: 330px;
            height: 330px;
            margin: 20px auto;
            padding: 18px;
            border-radius: 24px;
            background: #ffffff;
            display: grid;
            place-items: center;
          }

          .qr-box img {
            width: 285px;
            height: 285px;
          }

          .code {
            font-size: 28px;
            font-weight: 900;
            letter-spacing: 1px;
          }

          .alias {
            margin-top: 8px;
            color: #e5f6fb;
            font-weight: 700;
          }

          .info {
            margin-top: 20px;
            display: grid;
            gap: 10px;
          }

          .row {
            display: flex;
            justify-content: space-between;
            gap: 16px;
            padding: 13px 15px;
            background: #f8fcfd;
            border: 1px solid #e8f1f6;
            border-radius: 14px;
          }

          .row span {
            color: #64748b;
            font-weight: 800;
          }

          .row strong {
            color: #0f2f44;
            text-align: right;
          }

          .footer {
            margin-top: 18px;
            padding: 14px;
            border-radius: 16px;
            background: #fff7ed;
            color: #9a3412;
            font-size: 13px;
            line-height: 1.5;
            font-weight: 700;
          }

          .actions {
            max-width: 620px;
            margin: 18px auto 0;
            display: flex;
            justify-content: flex-end;
            gap: 10px;
          }

          button {
            border: none;
            border-radius: 14px;
            padding: 12px 18px;
            font-weight: 900;
            cursor: pointer;
          }

          .print {
            background: #1ba3c7;
            color: white;
          }

          .close {
            background: #e2e8f0;
            color: #0f2f44;
          }

          @media print {
            body {
              background: white;
              padding: 0;
            }

            .sheet {
              border: none;
              box-shadow: none;
              border-radius: 0;
              max-width: 100%;
            }

            .actions {
              display: none;
            }
          }
        </style>
      </head>

      <body>
        <div class="sheet">
          <div class="brand">
            <div class="brand-left">
              <div class="logo">ðŸ’§</div>
              <div>
                <h1>Agua Potable Huacariz</h1>
                <p class="subtitle">Ficha de identificaciÃ³n de suministro</p>
              </div>
            </div>

            <span class="tag">QR Suministro</span>
          </div>

          <div class="qr-section">
            <h2>CÃ³digo de suministro</h2>

            <div class="qr-box">
              <img src="${this.qrDataUrl}" alt="QR suministro">
            </div>

            <div class="code">${codigo}</div>
            <div class="alias">${alias}</div>
          </div>

          <div class="info">
            <div class="row">
              <span>Cliente</span>
              <strong>${cliente}</strong>
            </div>

            <div class="row">
              <span>DNI</span>
              <strong>${dni}</strong>
            </div>

            <div class="row">
              <span>DirecciÃ³n</span>
              <strong>${direccion}</strong>
            </div>

            <div class="row">
              <span>Uso del QR</span>
              <strong>Escaneo para registrar lectura</strong>
            </div>
          </div>

          <div class="footer">
            Este cÃ³digo identifica Ãºnicamente el suministro registrado en el sistema Agua Potable Huacariz.
            Debe colocarse en un lugar visible para facilitar el registro mensual de lectura.
          </div>
        </div>

        <div class="actions">
          <button class="close" onclick="window.close()">Cerrar</button>
          <button class="print" onclick="window.print()">Imprimir / guardar PDF</button>
        </div>
      </body>
      </html>
    `;

    ventana.document.open();
    ventana.document.write(html);
    ventana.document.close();
  }

  private textoSeguro(value: unknown): string {
    return String(value ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }
}
