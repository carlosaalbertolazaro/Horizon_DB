-- ============================================================
--  HORIZON DB — Migración v3 → v4
-- ============================================================
--  Usar este script SÓLO sobre una base que YA existe con datos
--  (el servidor EC2). Si vas a crear la base desde cero, usa
--  horizon_db_v4.sql en su lugar y NO ejecutes este archivo.
--
--  Todos los cambios son ADITIVOS: columnas nuevas que admiten
--  NULL. No se elimina ni se modifica nada existente, así que los
--  endpoints actuales siguen respondiendo igual y no es necesario
--  recompilar el backend de inmediato.
-- ============================================================

USE horizon_db;


-- ------------------------------------------------------------
-- 1. ZONA — coordenadas, descripción y deporte
-- ------------------------------------------------------------
-- El mapa interactivo del front necesita lat/lng para colocar los
-- pines, y el filtro por deporte necesita la relación con deporte.
-- DECIMAL(10,7) en lugar de FLOAT: precisión exacta de ~1 cm.
ALTER TABLE zona
    ADD COLUMN idDeporte   INT           NULL AFTER idGuia,
    ADD COLUMN descripcion TEXT          NULL AFTER nivel_dificultad,
    ADD COLUMN latitud     DECIMAL(10,7) NULL AFTER descripcion,
    ADD COLUMN longitud    DECIMAL(10,7) NULL AFTER latitud,
    ADD FOREIGN KEY (idDeporte) REFERENCES deporte(idDeporte);


-- ------------------------------------------------------------
-- 2. CLASE — datos de la tarjeta
-- ------------------------------------------------------------
-- titulo, descripcion, precio y duracion se muestran en la tarjeta
-- ANTES de que exista ninguna reserva. El precio de reserva vive en
-- la tabla reserva y no sirve para esto.
ALTER TABLE clase
    ADD COLUMN titulo      VARCHAR(200)  NULL AFTER idDeporte,
    ADD COLUMN descripcion TEXT          NULL AFTER titulo,
    ADD COLUMN duracion    VARCHAR(50)   NULL AFTER fecha,
    ADD COLUMN precio      DECIMAL(10,2) NULL AFTER duracion;


-- ------------------------------------------------------------
-- 3. EVENTO — datos de la tarjeta
-- ------------------------------------------------------------
ALTER TABLE evento
    ADD COLUMN titulo      VARCHAR(200)  NULL AFTER idZona,
    ADD COLUMN descripcion TEXT          NULL AFTER titulo,
    ADD COLUMN duracion    VARCHAR(50)   NULL AFTER fecha,
    ADD COLUMN precio      DECIMAL(10,2) NULL AFTER duracion;


-- ------------------------------------------------------------
-- 4. Índice compuesto de optimización
-- ------------------------------------------------------------
-- Si ya existe, MySQL devolverá error 1061; en ese caso ignóralo.
CREATE INDEX idx_reserva_evento_estado ON reserva(idEvento, estado);


-- ------------------------------------------------------------
-- 5. Verificación
-- ------------------------------------------------------------
-- Ejecutar después de la migración para confirmar los cambios:
--   DESCRIBE zona;
--   DESCRIBE clase;
--   DESCRIBE evento;
--   SHOW INDEX FROM reserva;


-- ============================================================
--  RECORDATORIO SOBRE NOMBRES DE TABLA
-- ============================================================
--  Este script asume tablas en MINÚSCULAS. Si tu base local las
--  tiene en mayúsculas, renómbralas antes:
--
--    SET FOREIGN_KEY_CHECKS = 0;
--    RENAME TABLE ROL TO rol;
--    RENAME TABLE USUARIO TO usuario;
--    RENAME TABLE GUIA TO guia;
--    RENAME TABLE EXPLORADOR TO explorador;
--    RENAME TABLE DOCUMENTO_GUIA TO documento_guia;
--    RENAME TABLE DEPORTE TO deporte;
--    RENAME TABLE ZONA TO zona;
--    RENAME TABLE CLASE TO clase;
--    RENAME TABLE EVENTO TO evento;
--    RENAME TABLE RESERVA TO reserva;
--    RENAME TABLE RESENA TO resena;
--    SET FOREIGN_KEY_CHECKS = 1;
--
--  En Linux MySQL distingue mayúsculas: las entidades JPA declaran
--  @Table(name="zona") y no encontrarían una tabla llamada ZONA.
-- ============================================================
