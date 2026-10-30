# Productividad y detenciones de la envasadora

Acceso: Reportes → Envasadora → Productividad y detenciones. También se puede
abrir desde VentoHaver TPT. Ruta: `/reporte-envasadora/productividad`.
Requiere sesión corporativa. Es un informe de consulta y usa las cargas existentes;
no incorpora otra carga de Excel ni modifica los reportes de origen.

## Fuentes y calendario

- Producción: `prodhaver` (sacos) y `horas_haver` del último reporte guardado por
  fecha y turno. Incluye borradores y enviados; no suma versiones del mismo turno.
  No usa inventarios, despachos, producción Vento ni Bigbag.
- Detenciones: eventos de `TptEvent`. Excluye duraciones negativas y muestra su
  cantidad para el período, días y turnos consultados. Omite eventos de duración cero.
- Horario confirmado: TM 06:00–14:00, TT 14:00–22:00, TN 22:00–06:00.
  TN se asigna a la fecha en que empieza, incluso después de medianoche.
- Programa: lunes a viernes, ocho horas por turno. Sábado, TM de 06:00 a 12:00
  (seis horas); los demás turnos del sábado y el domingo no tienen programación.
  Los eventos fuera de programa permanecen en el detalle y el Pareto, pero no
  integran la base programada de disponibilidad/MTBF/MTTR.

## Presentación

Reproduce las visualizaciones del dashboard de referencia
<https://dashboard-envasadora-ptm.netlify.app/> con Bootstrap, tarjetas y navegación
de la aplicación: producción por día/semana/mes y turno, promedios por día de la
semana y turno, Pareto con porcentaje acumulado, detalle del Pareto y detalle por
turno con enlace al reporte de origen. La tabla pagina en 60 filas; los totales y
gráficos siempre usan todo el período. Los gráficos se cargan mediante Stimulus
y Chart.js 4.4.3, la misma versión usada por otros gráficos de la aplicación.

Filtros: fechas, últimos 7/30 días, mes actual/anterior, todo, turnos, días de la
semana, agrupación del Pareto (razón, estado, impacto), primeras 5–25 causas e
inclusión del tiempo No programada. Los períodos rápidos se anclan en la última
fecha con datos. No seleccionar días/turnos equivale a seleccionar todos.

TPT no proporciona una columna independiente de equipo y otra de diagnóstico de
falla. Por eso se conserva su clasificación real sin inventar esa separación.
Las causas restantes se agrupan en Otros para que el Pareto llegue al 100%.

## Cálculos y límites

- Producción total: sacos Haver reportados. El promedio por turno incluye ceros
  declarados; un turno sin reporte es un dato ausente y no entra al promedio.
- Producción/hora: sacos / horas Haver declaradas; no usa una duración fija de turno.
  Si algún turno con producción positiva carece de horas declaradas no se calcula
  el cociente para no dividir toda la producción por una base parcial de horas.
- Detenido por turno: unión de intervalos detenidos seleccionados / turnos con TPT.
- Tiempo detenido: tiempo detenido / tiempo observado en TPT.
- Disponibilidad observada: tiempo registrado operativo / tiempo registrado de
  operación dentro del horario programado. Operación incluye Correr y paradas
  planificadas/no planificadas; excluye No programada. No se supone funcionamiento
  durante períodos sin datos. Cobertura TPT compara el tiempo observado con la
  duración programada del turno (8 o 6 horas).
- MTBF: horas operativas observadas / eventos de parada no planificada.
- MTTR: minutos detenidos no planificados / esos mismos eventos.
- Confiabilidad: `exp(-8 / MTBF)`, estimación para ocho horas bajo una hipótesis
  de tasa constante; no representa una garantía. Sin fallas observadas, MTBF,
  MTTR y confiabilidad se muestran sin dato.

Se recortan los eventos a los límites de fechas, días, turnos y programa; un
evento que cruza un límite reparte sus segundos y se cuenta una vez en el KPI
global. El detalle cuenta los eventos que tocan cada turno. Las uniones de
intervalos evitan duplicar segundos superpuestos en los KPI; el Pareto conserva
la suma de duraciones de los eventos, por lo que puede diferir si hay superposición.
Un turno sin producción o sin TPT muestra un guion en los campos ausentes.

Las horas TPT se interpretan literalmente, tal como se importan, sin convertir
zona horaria. Los horarios deben corresponder al reloj de la máquina.

Este informe calcula disponibilidad observada, no la disponibilidad teórica
del dashboard de referencia: la referencia supone tiempo programado cubierto,
mientras que aquí los vacíos de TPT se muestran como falta de cobertura.
