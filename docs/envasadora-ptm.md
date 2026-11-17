# Envasadora PTM

Módulo independiente de LCA, accesible en Informes → Envasadora PTM. El formulario registra un turno (fecha + TN/TM/TT), producción en sacos de 25 kg y una lista variable de detenciones. Todos los turnos tienen 480 minutos. Una producción vacía significa desconocida, no cero. El autor puede editar sus registros manuales; el histórico conserva sus filas originales.

## Importación inicial

Fuente: ENVASADORA PTM.xlsx, hoja Fallas envasadora, filas 2–7840. Se exportan los valores de B:J a JSON con claves row, shift, date, equipment, reason, minutes, production, state. Las fechas válidas se expresan en ISO. Se descartan filas completamente vacías. El turno se propaga desde la última celda informada, según instrucción del usuario. MES/AÑO se derivan de la fecha, evitando errores de columnas auxiliares.

El usuario confirmó dos correcciones: fila 3312, `1/01/0825` → 2025-08-01; fila 3364, `1/11/0825` → 2025-08-11. El texto original sigue almacenado en source_rows.

`PtmHistoryImporter` agrupa por fecha y turno. Conserva cada fila y el nombre original del equipo. Producciones múltiples por grupo se dejan sin valor calculado y se señalan para revisión; nunca se suman automáticamente. Se señalan también tiempos >480 minutos, tiempos faltantes y fechas posteriores al 17/11/2026. La importación completa es transaccional y las claves únicas impiden duplicarla. Ejecutar nuevamente omite los turnos ya importados; no reemplaza información.

La tarea `bin/rails ptm:import` recibe una línea JSON comprimida gzip y codificada base64 por stdin. `DRY_RUN=1` valida y devuelve el resumen sin guardar. No hay carga recurrente de Excel en la interfaz: los siguientes turnos se registran en el formulario.

Validación inicial: 7.839 filas, 1.768 turnos, 58 turnos con observaciones. Normalización de 153 variantes a 86 categorías. Se unifican mayúsculas, espacios, errores ortográficos y equivalencias explícitas en PtmEquipment; se mantienen equipos distintos (por ejemplo, filtros 512 y 513).

## Indicadores

- Toneladas: sacos × 0,025, solo producción informada.
- Rendimiento por hora de turno: toneladas / (8 × turnos con producción informada). No representa toneladas por hora efectiva de operación.
- Tiempo sin detenciones registradas: (480 − minutos de detención) / 480 por turno. El consolidado usa sumas de los turnos con tiempos utilizables. Se excluyen los grupos señalados y tiempos desconocidos. Incluye paradas operacionales, no equivale a confiabilidad mecánica.
- Paretos: minutos declarados por equipo/fase y por causa; las 12 categorías con más minutos, sin Otros. Los tiempos no tienen inicio/fin, por lo que no es posible descontar superposiciones históricas.
- No se calcula OEE, calidad ni confiabilidad sin los datos y la clasificación necesarios. No se reutiliza el ideal de Haver/LCA para PTM.

Los seis gráficos y la tabla usan el mismo período. Por defecto se muestra el mes anterior a la última fecha con registros hasta hoy. El rango Todo excluye fechas futuras; estas permanecen guardadas para revisión.

## Corrección del histórico autorizada el 17/11/2026

`bin/rails ptm:correct_history` aplica una corrección transaccional e idempotente sobre registros importados. Los valores originales siguen en `source_rows`; `history_adjustments` registra los minutos anteriores y el origen/destino de cada producción trasladada.

- Los minutos vacíos pasan a 1. Si el total supera 480, esos minutos se conservan en 1 y los demás se reducen proporcionalmente. Se distribuyen las centésimas restantes para que el total sea exactamente 480.
- La primera producción permanece en el turno original; cada producción adicional se propone al turno siguiente, en orden TN → TM → TT → TN del día siguiente. Si el destino no tiene producción, se traslada. Si ya tiene producción o es un registro manual, se descarta el valor adicional de los cálculos, según la indicación posterior del usuario (ejemplo: 7.108 sacos). Se conserva internamente en la auditoría y nunca se sobrescribe el destino. Un turno creado solo para recibir producción no recibe tiempos de detención inventados.
- Los paretos muestran las 12 categorías con más minutos del período, sin barra Otros. El porcentaje acumulado mantiene el total de todas las categorías como denominador y puede terminar por debajo de 100%.
