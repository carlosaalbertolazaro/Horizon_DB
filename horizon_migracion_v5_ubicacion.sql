-- ============================================================
--  HORIZON DB - Migración: ubicación del usuario
--  Aplicar sobre el esquema v5 ya instalado.
--      mysql -u root -p < horizon_migracion_v5_ubicacion.sql
-- ============================================================
--  Motivo: el perfil muestra la localidad del usuario, pero no
--  había dónde guardarla. Se derivaba de la primera actividad
--  reservada, lo que daba un dato incorrecto (la ubicación de
--  la ruta, no la del usuario) y no se podía editar.
--
--  Se guarda en `usuario` y no en `explorador` o `guia` para
--  que aplique a cualquier rol: los guías también tienen
--  localidad visible en su panel.
-- ============================================================

USE horizon_db;

ALTER TABLE usuario
    ADD COLUMN ubicacion VARCHAR(150) NULL AFTER foto_url;

-- Datos de las cuentas de prueba
UPDATE usuario SET ubicacion = 'Tuxtla Gutiérrez, Chiapas' WHERE correo = 'carlos@horizon.com';
UPDATE usuario SET ubicacion = 'Chiapa de Corzo, Chiapas'  WHERE correo = 'lucia@horizon.com';
UPDATE usuario SET ubicacion = 'San Cristóbal de las Casas, Chiapas' WHERE correo = 'alex@horizon.com';
UPDATE usuario SET ubicacion = 'Comitán, Chiapas'          WHERE correo = 'laura@horizon.com';

-- Verificación
SELECT idUsuario, nombre, correo, ubicacion FROM usuario;
