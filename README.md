# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## Autenticación con Google Workspace

El dashboard usa Google OAuth y permite únicamente cuentas cuyo claim de dominio
Workspace (`hd`) sea `msindustrial.cl`. Las sesiones expiran después de 12 horas
y no se guardan tokens de acceso de Google.

Configura un cliente OAuth 2.0 de tipo **Web application** en Google Cloud y
registra estas URI de redirección autorizadas:

- Desarrollo: `http://localhost:3000/auth/google_oauth2/callback`
- Producción: `https://impromaq-dashboard-e00010b0db83.herokuapp.com/auth/google_oauth2/callback`

Variables requeridas:

```text
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
GOOGLE_WORKSPACE_DOMAIN=msindustrial.cl
```

En Heroku se pueden cargar con:

```sh
heroku config:set GOOGLE_CLIENT_ID="..." GOOGLE_CLIENT_SECRET="..." GOOGLE_WORKSPACE_DOMAIN="msindustrial.cl" --app impromaq-dashboard
```

No publiques ni guardes `GOOGLE_CLIENT_SECRET` en el repositorio.

## Inspecciones en Works

Los trabajos nuevos usan la fecha actual de Chile, editable, y ofrecen Puerto Montt,
La Calera, Ventanas u Otro como planta. Al editar se conserva cualquier planta histórica.
Los correos nuevos incluyen un enlace firmado de solo lectura para consultar ese
reporte sin sesión. Quien recibe el enlace puede abrirlo y reenviarlo; no habilita
edición ni acceso al resto del sistema. Los enlaces dejan de servir si se elimina
el reporte. Los correos anteriores conservan sus enlaces originales y deben reenviarse
desde la aplicación para incluir el nuevo enlace compartido.

Ejecuta `bin/rails db:migrate` antes de iniciar la aplicación con esta versión.
Un trabajo admite una sola inspección, elegida en un desplegable, o un informe libre, sin inspección.
Las siete plantillas y sus preguntas están en `config/work_inspections.json`;
las preguntas se guardan junto con las respuestas para conservar su texto.
Cambiar de inspección la oculta del informe sin eliminar sus respuestas ni fotos;
al volver a elegirla se recuperan. El servidor rechaza más de una inspección activa por trabajo.

El listado `/works` permite filtrar por inspección, estado, planta, área y equipo.
El cumplimiento excluye pendientes y respuestas «No aplica»; se identifica como
provisional mientras queden preguntas sin responder. El informe y el correo
incluyen las respuestas y las fotos de cada ítem seleccionado.

Las fotos nuevas se optimizan en el navegador antes del envío: lado mayor de
1600 píxeles como máximo y JPEG al 72%, conservando el original si ya pesa menos.
La carga espera a que termine la optimización. Las fotos existentes se conservan.
