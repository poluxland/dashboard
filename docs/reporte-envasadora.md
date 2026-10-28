# Reporte envasadora

Acceso: menú Informe → Reporte envasadora. Requiere sesión corporativa.
El operador guarda el registro, revisa los totales y pulsa **Enviar reporte por correo**.
Solo su autor puede editarlo antes del envío o enviarlo. Después del envío queda cerrado. Los reportes guardados conservan sus medidas y cementos;
un envío confirmado no se repite. Los errores de correo dejan el registro guardado.
Ante un error de confirmación, revisar la recepción antes de reintentar.

La implementación adapta Medidas del proyecto ERP-Impromaq. No importa registros
históricos ni modifica ese proyecto. Destinatarios en `config/envasadora_recipients.json`,
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
  producción Bigbag: bolsas × 1,5 t. Rendimiento = toneladas / horas. Los nuevos datos se ingresan como enteros.
  Pantalla y correo muestran números redondeados sin decimales y con puntos entre miles;
  los cálculos conservan su precisión y no se modifican los registros históricos.
- Tolvas: capacidad × nivel / 100; 75 t para tolvas 4 y 5 de Silos 3000, 150 t las demás.
- Comparación TM/TT/TN: misma fecha declarada, último registro de cada turno anterior
  creado antes del reporte. No suma inventarios entre turnos ni usa otros días.

El correo HTML y la vista web comparten el reporte y los cálculos del modelo.
La fecha debe corresponder al día operativo elegido por quien registra el turno.
