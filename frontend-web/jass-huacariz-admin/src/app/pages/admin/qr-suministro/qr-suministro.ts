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

  qrDataUrl = '';
  error = '';

  constructor(private route: ActivatedRoute) {}

  ngOnInit(): void {
    this.route.queryParamMap.subscribe(params => {
      const codigo = params.get('codigo');
      const alias = params.get('alias');
      const direccion = params.get('direccion');

      if (codigo) {
        this.codigoSuministro = codigo.trim().toUpperCase();
        this.aliasSuministro = alias || '';
        this.direccionSuministro = direccion || '';
        this.generarQr();
      }
    });
  }

  async generarQr(): Promise<void> {
    this.error = '';
    this.qrDataUrl = '';

    const codigo = this.codigoSuministro.trim().toUpperCase();

    if (!codigo) {
      this.error = 'Ingrese el código del suministro.';
      return;
    }

    try {
      this.codigoSuministro = codigo;

      this.qrDataUrl = await QRCode.toDataURL(codigo, {
        width: 320,
        margin: 2,
        errorCorrectionLevel: 'H',
      });
    } catch {
      this.error = 'No se pudo generar el código QR.';
    }
  }

  limpiar(): void {
    this.codigoSuministro = '';
    this.aliasSuministro = '';
    this.direccionSuministro = '';
    this.qrDataUrl = '';
    this.error = '';
  }

  imprimirQr(): void {
    if (!this.qrDataUrl) {
      this.error = 'Primero genere el código QR.';
      return;
    }

    const codigo = this.textoSeguro(this.codigoSuministro);
    const alias = this.textoSeguro(this.aliasSuministro || 'Suministro de agua');
    const direccion = this.textoSeguro(this.direccionSuministro || '-');

    const ventana = window.open('', '_blank', 'width=700,height=700');

    if (!ventana) {
      this.error = 'El navegador bloqueó la ventana de impresión.';
      return;
    }

    const html = `
      <!DOCTYPE html>
      <html lang="es">
      <head>
        <meta charset="UTF-8">
        <title>QR Suministro ${codigo}</title>
        <style>
          * { box-sizing: border-box; }

          body {
            margin: 0;
            padding: 30px;
            font-family: Arial, sans-serif;
            background: #f3f7fa;
            color: #0f2f3d;
          }

          .sheet {
            max-width: 520px;
            margin: auto;
            background: #ffffff;
            border-radius: 20px;
            padding: 30px;
            border: 1px solid #dbe7ec;
            text-align: center;
          }

          .brand {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 12px;
            margin-bottom: 18px;
          }

          .logo {
            width: 56px;
            height: 56px;
            border-radius: 16px;
            background: #1ba3c7;
            color: white;
            display: grid;
            place-items: center;
            font-size: 28px;
          }

          h1, h2, p { margin: 0; }

          h1 {
            font-size: 24px;
            font-weight: 900;
          }

          .subtitle {
            color: #64748b;
            margin-top: 4px;
            font-size: 13px;
          }

          .qr-box {
            margin: 24px auto;
            padding: 18px;
            border-radius: 18px;
            background: #f8fcfd;
            border: 1px solid #e2eef3;
          }

          .qr-box img {
            width: 280px;
            height: 280px;
          }

          .code {
            font-size: 24px;
            font-weight: 900;
            letter-spacing: 1px;
            margin-top: 10px;
          }

          .info {
            margin-top: 18px;
            text-align: left;
            background: #f6fafc;
            padding: 16px;
            border-radius: 14px;
          }

          .info p {
            margin: 8px 0;
            color: #334155;
          }

          .info strong {
            color: #0f2f3d;
          }

          .footer {
            margin-top: 20px;
            color: #64748b;
            font-size: 12px;
            line-height: 1.5;
          }

          .actions {
            max-width: 520px;
            margin: 18px auto 0;
            display: flex;
            justify-content: flex-end;
            gap: 10px;
          }

          button {
            border: none;
            border-radius: 12px;
            padding: 12px 18px;
            font-weight: 800;
            cursor: pointer;
          }

          .print {
            background: #1ba3c7;
            color: white;
          }

          .close {
            background: #e2e8f0;
            color: #0f2f3d;
          }

          @media print {
            body {
              background: white;
              padding: 0;
            }

            .sheet {
              border: none;
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
            <div class="logo">💧</div>
            <div>
              <h1>JASS Huacariz</h1>
              <p class="subtitle">Código QR de suministro</p>
            </div>
          </div>

          <div class="qr-box">
            <img src="${this.qrDataUrl}" alt="QR suministro">
            <div class="code">${codigo}</div>
          </div>

          <div class="info">
            <p><strong>Alias:</strong> ${alias}</p>
            <p><strong>Dirección:</strong> ${direccion}</p>
            <p><strong>Uso:</strong> Escanear este código para registrar lectura del medidor.</p>
          </div>

          <div class="footer">
            Este código identifica únicamente el suministro registrado en el sistema JASS Huacariz.
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