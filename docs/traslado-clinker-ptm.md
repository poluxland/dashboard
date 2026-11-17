# Traslado de clínker PTM

Formulario: `/traslado-clinker-ptm/new`. Informe: `/traslado-clinker-ptm`.

Un registro diario con fecha, toneladas (hasta tres decimales) y observaciones opcionales. No admite fechas futuras, cantidades negativas ni dos registros para la misma fecha. El autor o un administrador puede editar. La carga histórica inicial queda editable por administradores.

Los filtros Semana pasada, Últimos 7 días, Últimos 30 días, Mes actual y Todo se calculan respecto de la fecha actual de la aplicación. El período inicial es Mes actual. Los días sin registro conservan valor desconocido; un cero explícito indica que no hubo traslado.

Indicadores: total, promedio por día registrado, máximo y cantidad de días informados. La tendencia diaria usa los días informados dentro de los últimos siete días naturales, incluyendo fechas anteriores al inicio del filtro. No conecta ni completa días sin registro. Totales semanales (lunes a domingo) y mensuales incluyen únicamente datos dentro del filtro y pueden ser parciales.

Carga inicial mediante `bin/rails clinker:import_initial`: 9–14/11/2026, interpretando «la semana pasada» respecto del martes 17/11/2026. Lunes 1.291 t, martes 943 t, miércoles 1.236 t, jueves 1.377 t, viernes 1.551 t, sábado 401 t. Total 6.799 t. No se crea domingo ni se reemplazan registros existentes al repetir la tarea.
