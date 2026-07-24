FIX FINAL - FILTROS COMPLETOS, RENDIMIENTO Y WHATSAPP

Incluye:
1. Recibos:
   - Al entrar carga rápido con límite inicial de 200.
   - Al aplicar filtro/búsqueda/periodo usa límite de 5000 para mostrar todos los recibos del mes/año seleccionado.
   - El enlace de WhatsApp ya no usa devtunnels. Usa window.location.origin y se adapta a IP o dominio.

2. Pagos:
   - Al entrar carga rápido con límite inicial de 200.
   - Al filtrar por mes/año/estado/búsqueda usa límite de 5000.

3. Historial de lecturas:
   - Al entrar carga rápido con límite inicial de 200.
   - Al filtrar por periodo/búsqueda usa límite de 5000.

4. Sin lectura registrada:
   - Muestra todos los suministros sin lectura del periodo, hasta 5000.

5. Dashboard:
   - Ya no carga todos los recibos/pagos de todos los años.
   - Carga por defecto el mes actual y hasta 5000 registros.
   - Si el usuario cambia año/mes y actualiza, consulta ese periodo.

6. Reportes:
   - Ya no carga todos los recibos/pagos de todos los años.
   - Carga por defecto el mes actual y hasta 5000 registros.
   - Se agregó filtro de mes/año y botón para volver al mes actual.

Luego de aplicar:
- mvn clean package -DskipTests
- npm run build
- commit/push
- desplegar backend y frontend en VPS
