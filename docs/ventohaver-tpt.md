# VentoHaver TPT

Disponible para usuarios autenticados en Mantenimiento → VentoHaver TPT (`/ventohaver-tpt`).
Acepta cargas manuales periódicas XLSX de hasta 10 MB para una única máquina.
No requiere modificar el informe original.

Se busca la fila de las diez cabeceras dentro de las primeras 50 filas. Se usa
la hoja Datos TPT, o la primera hoja si no existe una con ese nombre. Las filas
posteriores sin Hora de inicio son subtotales; no se importan. Cada evento
requiere impacto, estado, razón, hora de inicio, una ocurrencia y duración total
en segundos. Los encabezados pueden moverse a la primera fila conservando las
diez columnas. Las fechas deben conservar su tipo fecha de Excel o usar texto
AAAA-MM-DD HH:MM:SS, con hasta seis decimales de segundo.

Se conservan la fila de origen, la fecha y la duración con seis decimales. La
hora se almacena como hora literal del informe, sin inferir su zona horaria;
la interfaz la muestra sin conversiones. Los porcentajes y estadísticas del
período exportado no se acumulan: las horas se calculan desde los eventos.
Las duraciones negativas se conservan, se señalan y se excluyen de las horas.

La combinación de impacto, estado, razón y hora de inicio identifica un evento.
Una carga superpuesta omite eventos idénticos. Si cambia la duración del mismo
evento, informa la fila y conserva la versión anterior para evitar sumar dos
veces. Sin identificadores estables del sistema de origen, una corrección de
hora o clasificación se verá como un evento nuevo y requiere revisión manual.

El historial conserva nombre del archivo, usuario, fecha, conteos e incidencias;
no almacena el archivo binario. Los archivos inválidos se rechazan; las filas
inválidas se detallan y las válidas se incorporan en una transacción.

Aplicar `bin/rails db:migrate` al desplegar.
