OPTIMIZACION WEB 12K - JASS HUACARIZ

Cambios incluidos:
- Clientes backend: evita N+1, carga usuarios y suministros agrupados.
- Recibos backend: filtros por anio, mes, estado, busqueda y limit.
- Pagos backend: filtros por anio, mes, estado, busqueda y limit.
- Historial lecturas backend: consulta optimizada sin N+1 por recibo.
- Sin lecturas backend: limit y busqueda.
- Web Angular: Recibos, Pagos e Historial cargan por defecto mes/anio actual y maximo 200 registros.
- Migracion V14 con indices IF NOT EXISTS para rendimiento.

Extraer este ZIP desde la raiz C:\Users\user\Desktop\Unity\Proyecto_Agua.
Despues ejecutar build backend y frontend antes de hacer commit.
