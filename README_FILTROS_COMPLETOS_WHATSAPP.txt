FIX filtros completos + WhatsApp

Cambios:
- Recibos, Pagos e Historial cargan 200 registros al ingresar para mantener la pantalla rápida.
- Cuando el usuario escribe, cambia estado, mes o año, se activa filtro completo hasta 5000 registros.
- Sin lectura conserva límite alto para mostrar todos los pendientes del periodo.
- El enlace de WhatsApp deja de usar devtunnels y toma automáticamente el dominio actual con window.location.origin.

En producción, cuando el sistema esté en HTTPS, el mensaje enviará por ejemplo:
https://sistema.tudominio.com/cliente/mis-recibos
