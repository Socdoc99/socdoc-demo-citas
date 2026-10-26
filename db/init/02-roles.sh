#!/bin/bash
# Crea el usuario n8n_app con el mínimo privilegio que necesitan los flujos.
# Corre una sola vez, después de 01-schema.sql. La contraseña viene de APP_DB_PASSWORD.
set -e

psql -v ON_ERROR_STOP=1 \
  -v app_pw="$APP_DB_PASSWORD" \
  -v dbname="$POSTGRES_DB" \
  --username "$POSTGRES_USER" \
  --dbname "$POSTGRES_DB" <<'EOSQL'
CREATE ROLE n8n_app LOGIN PASSWORD :'app_pw';

GRANT CONNECT ON DATABASE :"dbname" TO n8n_app;
GRANT USAGE ON SCHEMA public TO n8n_app;

-- Citas: leer, crear y actualizar. No puede borrar ni cambiar la estructura.
GRANT SELECT, INSERT, UPDATE ON citas TO n8n_app;
GRANT USAGE, SELECT ON SEQUENCE citas_id_seq TO n8n_app;

-- Configuración: solo leer. El modo demo se cambia con el usuario administrador.
GRANT SELECT ON config TO n8n_app;

-- Panel: solo leer el resumen.
GRANT SELECT ON v_resumen TO n8n_app;
EOSQL
