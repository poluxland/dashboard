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
