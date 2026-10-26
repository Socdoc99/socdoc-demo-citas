-- Demo de citas con recordatorios. Todos los datos son ficticios.
-- Este script corre una sola vez, cuando se crea el volumen de Postgres por primera vez.

-- Configuración editable sin tocar los flujos (por ejemplo, el modo demo).
CREATE TABLE config (
  clave text PRIMARY KEY,
  valor text NOT NULL
);

-- Minutos de anticipación del recordatorio: 1440 = 24 horas (modo real), 2 = modo demo.
INSERT INTO config (clave, valor) VALUES ('recordatorio_minutos_antes', '1440');

CREATE TABLE citas (
  id               bigserial PRIMARY KEY,
  paciente_nombre  text        NOT NULL,
  telegram_chat_id bigint,
  motivo           text        NOT NULL DEFAULT 'Valoración',
  inicio           timestamptz NOT NULL,
  estado           text        NOT NULL DEFAULT 'agendada'
    CHECK (estado IN ('agendada', 'recordada', 'confirmada', 'cancelada', 'asistio', 'no_asistio')),
  creada_en        timestamptz NOT NULL DEFAULT now(),
  recordada_en     timestamptz,
  respondida_en    timestamptz,
  cancelada_en     timestamptz,
  CHECK (estado <> 'cancelada' OR cancelada_en IS NOT NULL)
);

-- Un horario solo puede tener una cita activa. Una cita cancelada libera el horario.
CREATE UNIQUE INDEX citas_horario_activo ON citas (inicio) WHERE estado <> 'cancelada';
CREATE INDEX citas_estado_inicio ON citas (estado, inicio);

-- Resumen para el panel.
-- Una cita cancelada cuenta como recuperada si otra persona reservó después el mismo horario.
CREATE VIEW v_resumen AS
WITH recuperadas AS (
  SELECT c.id
  FROM citas c
  WHERE c.estado = 'cancelada'
    AND EXISTS (
      SELECT 1
      FROM citas r
      WHERE r.inicio = c.inicio
        AND r.estado <> 'cancelada'
        AND r.creada_en > c.cancelada_en
    )
)
SELECT
  count(*)                                       AS total,
  count(*) FILTER (WHERE estado = 'asistio')     AS asistencias,
  count(*) FILTER (WHERE estado = 'no_asistio')  AS inasistencias,
  count(*) FILTER (WHERE estado = 'cancelada')   AS cancelaciones,
  (SELECT count(*) FROM recuperadas)             AS recuperadas
FROM citas;
