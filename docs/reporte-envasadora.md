# Reporte envasadora

Acceso: menú Reportes → Envasadora. Requiere sesión corporativa.
El operador guarda el registro, revisa los totales y pulsa **Enviar reporte por correo**.
Solo su autor puede editarlo antes del envío o enviarlo. Después del envío queda cerrado. Los reportes guardados conservan sus medidas y cementos;
un envío confirmado no se repite. Los errores de correo dejan el registro guardado.
Ante un error de confirmación, revisar la recepción antes de reintentar.

La implementación adapta Medidas del proyecto ERP-Impromaq y permite incorporar
históricos de su exportación sin modificar ese proyecto. Destinatarios en `config/envasadora_recipients.json`,
temporalmente limitada para pruebas a José Jerez, Fernando González y Claudio Villanueva,
sin destinatarios adicionales por horario.
Las pruebas usan entrega simulada, sin correos reales.

## Cálculos

- Silos 19–22: `(30 - promedio(medida1, medida2)) × 100` toneladas.
- Silo 27: `(30 - medida) × 460` toneladas.
- Silo 28: `(20 - medida) × 100` toneladas.
- Cementos iniciales: 19 Extra, 20 S4200, 21 Extra, 22 Ultra, 27 Especial, 28 Ultra.
- El inventario agrupa por el cemento guardado en cada silo. Cambiarlo transfiere
  las toneladas al producto seleccionado, sin cambiar el total físico.
- Stock de piso: se mantienen los componentes de ERP; Bigbag Plus también figura
  en su producto y en el total. Stock, despachos y bigbags de piso se ingresan en toneladas.
- Solubles, plastificado y tolvas se muestran aparte para evitar duplicar inventario.
- Plastificado: pallets × 1,8 t. Producción Haver/Vento: sacos × 0,025 t;
  producción Bigbag: bolsas × 1,5 t. Rendimiento = toneladas / horas. Medidas, horas y cantidades en toneladas admiten decimales;
  sacos, bolsas, pallets y enjuagues se ingresan como enteros.
  Haver, Vento y Bigbag admiten de 0 a 8 horas por turno; sábado TM, de 0 a 6.
  El formulario actualiza los máximos al cambiar fecha/turno y el modelo valida
  el límite también en el servidor.
  Pantalla y correo muestran las toneladas sin decimales y con puntos entre miles;
  las medidas y horas conservan hasta dos decimales cuando los necesitan.
  Cumplimiento y toneladas estimadas de tolvas se truncan como en el original;
  los cálculos conservan su precisión y no se modifican los registros históricos.
- Tolvas: capacidad × nivel / 100; 75 t para tolvas 4 y 5 de Silos 3000, 150 t las demás.
- Comparación TM/TT/TN: misma fecha declarada, último registro de cada turno anterior
  creado antes del reporte. No suma inventarios entre turnos ni usa otros días.

El correo HTML y la vista web comparten el reporte y los cálculos del modelo.
La fecha debe corresponder al día operativo elegido por quien registra el turno.

## Orden del reporte

1. Inventario por tipo (TM/TT/TN).
2. Inventario de sacos, incluidos solubles y plastificado (TM/TT/TN).
3. Inventario de bigbags (TM/TT/TN).
4. Inventario de silos: producto seleccionado, toneladas y medidas.
5. Inventario total combinado: silos y piso por producto (TM/TT/TN).
6. Despachos (TM/TT/TN).
7. Producciones: unidades, cumplimiento, horas, rendimiento y comentarios.
8. Nivel de tolvas.
9. Calles operativas.
10. Estado de calles: estado, cemento y comentarios en la misma fila.
11. Enjuagues y observaciones.

Web y ambos formatos de correo comparten las tablas de `EnvasadoraReportPresenter`.
Cada columna del inventario combinado agrupa los silos según el cemento seleccionado
en el registro de ese turno. El formulario de tolvas mantiene dos columnas.

## Histórico importado

El histórico de Impromaq-5.xlsx usa solo filas con TM, TT o TN. Según la regla
confirmada por el usuario, la primera fila del archivo por fecha y turno es la
más reciente: se descartan las versiones posteriores y las filas sin turno.
Se conservan archivo, hoja, fila, huella SHA256 y todas las columnas originales,
incluidos resultados calculados y columnas que no tienen un campo editable.

La carga administrativa usa `EnvasadoraHistoryImporter` y la tarea
`envasadora:import_history`. Recibe por stdin un JSON comprimido con gzip y
codificado en base64. `DRY_RUN=1` prepara el resumen sin guardar. Los datos no
se guardan en Git ni se publican como archivos web. Las huellas de origen
impiden duplicar una carga idéntica.

Los históricos son de consulta: no se editan ni se envían por correo. Su vista
muestra valores originales y celdas vacías como guiones; los valores fuera de
las reglas actuales quedan señalados, sin corregirlos. La lista ofrece filtros
de fecha/turno y paginación de 50 registros para consultar el histórico completo.

Las horas ausentes o fuera de rango no se consideran horas válidas para el
rendimiento del dashboard. Tampoco se usan cantidades negativas o campos que
incumplen las validaciones actuales en sus indicadores. El inventario de la lista
queda sin dato si faltan componentes o hay mediciones inválidas.

La sustitución del ensayo inicial verifica su ID y sus atributos antes de
eliminarlo, exige que sea el único registro y agrupa eliminación e inserción en
una transacción. Si algo cambia o falla, la operación se revierte. El respaldo
del ensayo se conserva localmente fuera de Git.

Las correcciones administrativas puntuales de horas guardan valor anterior,
valor corregido, motivo y fecha en `source_data.corrections`. La celda original
se conserva, la vista identifica el cambio y el valor corregido se habilita
para los indicadores. La corrección no habilita edición o envío de históricos.
