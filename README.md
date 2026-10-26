# Demo: citas con recordatorios (n8n + Postgres)

Demo de automatización para negocios con citas. Simula un consultorio odontológico ficticio: el cliente reserva en un formulario, recibe un recordatorio por Telegram con botones para confirmar o cancelar, y un panel muestra asistencias, cancelaciones y citas recuperadas.

Hecha por Santiago Ospina ([SocDoc](https://socdoc.tech)). Todos los datos son ficticios.

**Estado:** en construcción. Meta: demo, video y página de servicios publicados el 16 de noviembre de 2026.

## Qué incluye

- Postgres con la tabla de citas, una restricción que impide dos citas activas en el mismo horario y un resumen para el panel.
- n8n Community con los flujos de reserva, recordatorio, respuesta y panel.
- Un usuario de base de datos con el mínimo privilegio para los flujos.

## Requisitos

- Docker con Docker Compose.
- Un bot de Telegram propio (se crea con BotFather, es gratis).
- Git Bash o WSL en Windows para generar secretos con `openssl`.

## Arranque

1. Copia el archivo de ejemplo y completa los valores:

   ```bash
   cp .env.example .env
   openssl rand -hex 32   # úsalo para N8N_ENCRYPTION_KEY, POSTGRES_PASSWORD y APP_DB_PASSWORD (uno distinto por variable)
   ```

2. Levanta los servicios:

   ```bash
   docker compose up -d
   docker compose ps
   ```

3. Abre n8n en http://localhost:5678 y crea la cuenta de propietario.
4. En n8n crea dos credenciales:
   - **Postgres:** host `db`, puerto `5432`, base `citas`, usuario `n8n_app` y la contraseña de `APP_DB_PASSWORD`.
   - **Telegram:** el token que entrega BotFather. El token se guarda cifrado en n8n y nunca va en el repo.

Los scripts de `db/init/` corren solo la primera vez, cuando se crea el volumen. Para reiniciar la base desde cero: `docker compose down -v` (borra también los flujos de n8n; exporta antes).

## Modo demo

El recordatorio sale con 1440 minutos de anticipación (24 horas). En modo demo sale con 2 minutos, para poder mostrarlo en un video.

Abre una consola de Postgres como administrador:

```bash
docker compose exec db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"'
```

Activar el modo demo:

```sql
UPDATE config SET valor = '2' WHERE clave = 'recordatorio_minutos_antes';
```

Volver al modo real:

```sql
UPDATE config SET valor = '1440' WHERE clave = 'recordatorio_minutos_antes';
```

## Exportar los flujos

Para versionar los flujos sin credenciales:

```bash
docker compose exec -u node n8n n8n export:workflow --all --separate --output=/home/node/workflows/
```

No exportes credenciales. La carpeta `workflows/` ya ignora los archivos que contengan `credentials` o `secret` en el nombre.

## Seguridad

- Los puertos de Postgres y n8n solo escuchan en `127.0.0.1`. No son accesibles desde la red local.
- Los secretos viven en `.env`, que está en `.gitignore`. Solo se sube `.env.example`, sin valores.
- Los flujos usan el usuario `n8n_app`: puede leer y escribir citas, leer la configuración y el resumen. No puede borrar datos ni cambiar la estructura.
- Antes de cada `git push`, revisa que no haya secretos: `git status` y `git diff --staged`. Opcional: [gitleaks](https://github.com/gitleaks/gitleaks) sobre el historial.
- Solo datos ficticios. Si un cliente real usa este sistema, el negocio necesita autorización de tratamiento de datos personales (Ley 1581 de 2012).

## Nota de licencia de n8n

Esta demo corre n8n Community en un equipo personal. En un cliente real, n8n se despliega en la cuenta o el servidor del cliente: la licencia Sustainable Use no permite alojar flujos y credenciales de varios clientes en una instancia propia ni darles acceso a ella. Más información: [docs.n8n.io](https://docs.n8n.io/n8n-community-license/community-license/license-faq).

## Estructura

```
.
├── docker-compose.yml      # Postgres + n8n
├── .env.example            # variables sin valores
├── db/init/
│   ├── 01-schema.sql       # tablas, restricciones y resumen
│   └── 02-roles.sh         # usuario n8n_app con mínimo privilegio
└── workflows/              # flujos exportados (sin credenciales)
```

## Bitácora de cambios

Una línea por cambio: fecha, qué cambió y por qué.

| Fecha | Cambio | Motivo |
|---|---|---|
| 2026-10-21 | Estructura inicial: Docker Compose con Postgres y n8n, esquema de citas y usuario de mínimo privilegio | Base de la demo de las 4 semanas |
