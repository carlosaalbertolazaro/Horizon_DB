-- ============================================================
--  HORIZON DB — Script de esquema completo (v5)
-- ============================================================
--  Proyecto Integrador — Plataforma de ecoturismo, Chiapas
--  Responsable de BD e infraestructura: Carlos
--
--  Esta es la VERSIÓN CANÓNICA del esquema.
--  Cualquier cambio en la estructura se hace primero aquí.
--
--  Crea la base COMPLETA desde cero. Si la base ya existe con
--  datos, no ejecutes este archivo: usa los scripts de migración.
--
--  CAMBIOS DE LA v3 A LA v4:
--    1. Nombres de tabla en MINÚSCULAS (obligatorio, ver nota abajo)
--    2. zona:   + latitud, longitud, descripcion, idDeporte
--    3. clase:  + titulo, descripcion, precio, duracion
--    4. evento: + titulo, descripcion, precio, duracion
--    5. Índices de optimización incluidos
--
--  CAMBIOS DE LA v4 A LA v5:
--    6. Tabla favorito (pestaña "Guardados" del perfil)
--    7. Restricción CHECK que fuerza la regla XOR de reserva
--    8. Vistas vw_cupos_evento y vw_cupos_clase
--
--  NOTA CRÍTICA — MAYÚSCULAS:
--    En Linux, MySQL SÍ distingue mayúsculas en nombres de tabla.
--    El servidor corre Ubuntu, por lo que TODAS las tablas van en
--    minúsculas. Las entidades JPA deben declarar @Table(name="zona"),
--    no "ZONA". Crear las tablas en mayúsculas rompe el backend en
--    producción aunque funcione en Windows.
--
--  NOTA — HIBERNATE:
--    En application.properties es obligatorio:
--      spring.jpa.hibernate.ddl-auto=none
--      spring.jpa.hibernate.naming.physical-strategy=
--        org.hibernate.boot.model.naming.PhysicalNamingStrategyStandardImpl
--    Sin la primera, Hibernate altera el esquema y crea columnas
--    duplicadas en snake_case. Sin la segunda, traduce idGuia a
--    id_guia y ninguna consulta encuentra sus columnas.
--
--  NOTA — ARCHIVOS:
--    Ningún binario se guarda en la base de datos. Las imágenes y
--    documentos viven en S3; aquí sólo se almacena su URL.
--      /fotos/       -> pública  (perfiles, reseñas, actividades)
--      /documentos/  -> privada  (identificaciones, certificaciones)
-- ============================================================

CREATE DATABASE IF NOT EXISTS horizon_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE horizon_db;


-- ============================================================
-- 1. AUTENTICACIÓN Y USUARIOS
-- ============================================================

-- Catálogo controlado de roles.
-- IDs fijos: 1 = EXPLORADOR, 2 = GUIA, 3 = ADMIN
CREATE TABLE rol (
    idRol   INT AUTO_INCREMENT,
    nombre  VARCHAR(50) NOT NULL,
    PRIMARY KEY (idRol)
);

-- Tabla central de cuentas. Todo usuario del sistema vive aquí,
-- sin importar su rol. El correo es UNIQUE: es el identificador
-- de login y evita cuentas duplicadas entre roles.
CREATE TABLE usuario (
    idUsuario       INT AUTO_INCREMENT,
    idRol           INT           NOT NULL,
    nombre          VARCHAR(100)  NOT NULL,
    correo          VARCHAR(150)  NOT NULL UNIQUE,
    password_hash   VARCHAR(255)  NOT NULL,
    foto_url        VARCHAR(500)  NULL,
    fecha_registro  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (idUsuario),
    FOREIGN KEY (idRol) REFERENCES rol(idRol)
);

-- Perfil extendido del guía. Relación 1:1 con usuario.
-- Al registrar: INSERT en usuario (idRol = 2), luego aquí.
CREATE TABLE guia (
    idGuia              INT AUTO_INCREMENT,
    idUsuario           INT           NOT NULL UNIQUE,
    especialidad        VARCHAR(100)  NULL,
    experiencia_anios   INT           NULL,
    descripcion         TEXT          NULL,
    foto_url            VARCHAR(500)  NULL,
    PRIMARY KEY (idGuia),
    FOREIGN KEY (idUsuario) REFERENCES usuario(idUsuario)
);

-- Perfil extendido del explorador. Relación 1:1 con usuario.
-- Al registrar: INSERT en usuario (idRol = 1), luego aquí.
-- nivel: PRINCIPIANTE, INTERMEDIO, AVANZADO
CREATE TABLE explorador (
    idExplorador    INT AUTO_INCREMENT,
    idUsuario       INT          NOT NULL UNIQUE,
    nivel           VARCHAR(50)  NULL,
    foto_url        VARCHAR(500) NULL,
    PRIMARY KEY (idExplorador),
    FOREIGN KEY (idUsuario) REFERENCES usuario(idUsuario)
);


-- ============================================================
-- 2. CATÁLOGOS
-- ============================================================

CREATE TABLE deporte (
    idDeporte   INT AUTO_INCREMENT,
    tipo        VARCHAR(100) NOT NULL,
    PRIMARY KEY (idDeporte)
);

-- Zonas / rutas del mapa interactivo.
--
--   nivel_dificultad -> FACIL, MEDIO, DIFICIL
--       Coincide con los botones de filtro del front.
--       El front debe normalizar antes de comparar: los JSON de
--       maqueta traen "facil", "Fácil", "Difícil" (acentos y
--       minúsculas), y aquí se guarda sin acento y en mayúsculas.
--
--   idGuia -> guía que propuso la zona. NULL = zona base del sistema.
--       Se guarda el ID, NO el nombre. El nombre se obtiene con JOIN
--       a usuario; duplicarlo provocaría desincronización.
--       No hay validación de administrador: el control de riesgo está
--       en la verificación previa de identidad del guía. El backend
--       DEBE validar que el usuario tenga rol GUIA antes del INSERT.
--
--   latitud / longitud -> pines del mapa interactivo.
--       DECIMAL(10,7) da precisión de ~1 cm, suficiente y exacto
--       (a diferencia de FLOAT, que redondea).
CREATE TABLE zona (
    idZona           INT AUTO_INCREMENT,
    idGuia           INT           NULL,
    idDeporte        INT           NULL,
    nombre_zona      VARCHAR(150)  NOT NULL,
    ubicacion        VARCHAR(255)  NULL,
    nivel_dificultad VARCHAR(50)   NULL,
    descripcion      TEXT          NULL,
    latitud          DECIMAL(10,7) NULL,
    longitud         DECIMAL(10,7) NULL,
    PRIMARY KEY (idZona),
    FOREIGN KEY (idGuia)    REFERENCES guia(idGuia),
    FOREIGN KEY (idDeporte) REFERENCES deporte(idDeporte)
);


-- ============================================================
-- 3. ACTIVIDADES
-- ============================================================

-- Clase impartida por un guía en una ubicación libre.
--
--   titulo / descripcion / precio / duracion -> los muestra la
--       tarjeta del front antes de que exista ninguna reserva.
--   precio -> DECIMAL, nunca DOUBLE: el punto flotante introduce
--       errores de redondeo inaceptables en valores monetarios.
--   duracion -> texto libre ("6 Horas", "Día Completo") porque el
--       front lo muestra tal cual y no se opera aritméticamente.
--
-- Validar en backend: fecha >= NOW() al crear.
-- Control de cupos: COUNT(reservas CONFIRMADAS) < capacidad.
CREATE TABLE clase (
    idClase     INT AUTO_INCREMENT,
    idGuia      INT           NOT NULL,
    idDeporte   INT           NOT NULL,
    titulo      VARCHAR(200)  NULL,
    descripcion TEXT          NULL,
    ubicacion   VARCHAR(255)  NULL,
    fecha       TIMESTAMP     NOT NULL,
    duracion    VARCHAR(50)   NULL,
    precio      DECIMAL(10,2) NULL,
    capacidad   INT           NOT NULL,
    foto_url    VARCHAR(500)  NULL,
    PRIMARY KEY (idClase),
    FOREIGN KEY (idGuia)    REFERENCES guia(idGuia),
    FOREIGN KEY (idDeporte) REFERENCES deporte(idDeporte)
);

-- Evento en una zona registrada. A diferencia de clase, no lleva
-- guía asignado y sí está ligado a una zona: por eso es la tabla
-- que alimenta la estadística de zonas más visitadas.
CREATE TABLE evento (
    idEvento    INT AUTO_INCREMENT,
    idDeporte   INT           NOT NULL,
    idZona      INT           NOT NULL,
    titulo      VARCHAR(200)  NULL,
    descripcion TEXT          NULL,
    fecha       TIMESTAMP     NOT NULL,
    duracion    VARCHAR(50)   NULL,
    precio      DECIMAL(10,2) NULL,
    capacidad   INT           NOT NULL,
    foto_url    VARCHAR(500)  NULL,
    PRIMARY KEY (idEvento),
    FOREIGN KEY (idDeporte) REFERENCES deporte(idDeporte),
    FOREIGN KEY (idZona)    REFERENCES zona(idZona)
);


-- ============================================================
-- 4. TRANSACCIONES
-- ============================================================

-- REGLA CRÍTICA: (idClase IS NULL) XOR (idEvento IS NULL)
--   Una reserva corresponde a UNA clase O a UN evento, nunca a
--   ambos ni a ninguno. La restricción chk_reserva_clase_o_evento
--   la impone a nivel de base de datos (MySQL 8.0.16+).
--
--   Cómo funciona: (idClase IS NULL) devuelve 1 o 0. El operador <>
--   exige que ambos difieran, es decir, que exactamente uno tenga
--   valor.
--     clase = 5,    evento = NULL  ->  0 <> 1  ->  válido
--     clase = NULL, evento = 3     ->  1 <> 0  ->  válido
--     clase = 5,    evento = 3     ->  0 <> 0  ->  RECHAZADO
--     clase = NULL, evento = NULL  ->  1 <> 1  ->  RECHAZADO
--
--   La restricción NO sustituye la validación en el backend: el
--   controlador debe seguir verificándolo para devolver un mensaje
--   claro al usuario. Es la última línea de defensa, la que impide
--   que entre un dato inválido por cualquier otra vía.
--
-- estado: PENDIENTE, CONFIRMADA, CANCELADA
--   Sólo las CONFIRMADAS cuentan para estadísticas y cupos.
--   Una intención de reserva no equivale a una visita.
--
-- precio_reserva: se copia el precio vigente al momento de reservar.
--   Es deliberado: si la actividad sube de precio después, la
--   reserva histórica debe conservar lo que el usuario pagó.
CREATE TABLE reserva (
    idReserva       INT AUTO_INCREMENT,
    idExplorador    INT             NOT NULL,
    idClase         INT             NULL,
    idEvento        INT             NULL,
    precio_reserva  DECIMAL(10,2)   NOT NULL,
    fecha_reserva   TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado          VARCHAR(20)     NOT NULL DEFAULT 'PENDIENTE',
    PRIMARY KEY (idReserva),
    FOREIGN KEY (idExplorador) REFERENCES explorador(idExplorador),
    FOREIGN KEY (idClase)      REFERENCES clase(idClase),
    FOREIGN KEY (idEvento)     REFERENCES evento(idEvento),
    CONSTRAINT chk_reserva_clase_o_evento
        CHECK ((idClase IS NULL) <> (idEvento IS NULL))
);

-- Una reserva = máximo una reseña (idReserva es UNIQUE).
-- Sólo permitir reseña si la reserva está CONFIRMADA.
-- calificacion: validar rango 1–5 en backend.
CREATE TABLE resena (
    idResena        INT AUTO_INCREMENT,
    idReserva       INT           NOT NULL UNIQUE,
    calificacion    INT           NOT NULL,
    comentario      TEXT          NULL,
    foto_url        VARCHAR(500)  NULL,
    fecha           TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (idResena),
    FOREIGN KEY (idReserva) REFERENCES reserva(idReserva)
);


-- ============================================================
-- 5. DOCUMENTOS DEL GUÍA
-- ============================================================
-- Identificación oficial y certificaciones. Los archivos viven en
-- la carpeta PRIVADA de S3; abrir estas URLs en el navegador
-- devuelve AccessDenied, que es el comportamiento correcto.
--
-- Es tabla separada y no columnas fijas en guia porque un guía
-- puede subir una identificación y varias certificaciones.
--
-- tipo: INE, CERTIFICACION
CREATE TABLE documento_guia (
    idDocumento   INT AUTO_INCREMENT,
    idGuia        INT           NOT NULL,
    tipo          VARCHAR(50)   NOT NULL,
    url           VARCHAR(500)  NOT NULL,
    fecha_subida  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (idDocumento),
    FOREIGN KEY (idGuia) REFERENCES guia(idGuia)
);


-- ============================================================
-- 6. FAVORITOS
-- ============================================================
-- Alimenta la pestaña "Guardados" del perfil.
-- Relación muchos-a-muchos entre usuario y evento.
--
-- La UNIQUE KEY (idUsuario, idEvento) es lo que hace correcta esta
-- tabla: impide que el mismo usuario guarde dos veces la misma
-- actividad. Sin ella, cada clic en el botón crearía una fila nueva
-- y la lista se llenaría de duplicados. Con ella, el backend puede
-- insertar sin consultar antes: si ya existe, MySQL rechaza el
-- INSERT y ese error es la señal de "ya estaba guardado".
--
-- ON DELETE CASCADE: si se elimina el usuario o el evento, sus
-- favoritos desaparecen solos. Un favorito no significa nada por sí
-- mismo, a diferencia de una reserva, que es registro histórico y
-- por eso allí NO se usa cascada.
--
-- Apunta a evento y no a zona porque lo que el front guarda son
-- actividades reservables, no ubicaciones del mapa.
CREATE TABLE favorito (
    idFavorito   INT AUTO_INCREMENT,
    idUsuario    INT       NOT NULL,
    idEvento     INT       NOT NULL,
    fecha        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (idFavorito),
    UNIQUE KEY uk_favorito (idUsuario, idEvento),
    FOREIGN KEY (idUsuario) REFERENCES usuario(idUsuario) ON DELETE CASCADE,
    FOREIGN KEY (idEvento)  REFERENCES evento(idEvento)   ON DELETE CASCADE
);


-- ============================================================
-- 7. CATÁLOGOS BASE
-- ============================================================

INSERT INTO rol (nombre) VALUES
    ('EXPLORADOR'),
    ('GUIA'),
    ('ADMIN');

INSERT INTO deporte (tipo) VALUES
    ('Escalada'),
    ('Senderismo'),
    ('Pesca'),
    ('Kayak');


-- ============================================================
-- 8. ÍNDICES DE OPTIMIZACIÓN
-- ============================================================
-- MySQL indexa automáticamente las llaves primarias y foráneas.
-- Estos cubren las columnas por las que se FILTRA.
--
-- idx_reserva_evento_estado es COMPUESTO y el orden importa:
--   primero idEvento (columna del JOIN), después estado (filtro).
--   Un índice sólo sobre estado no se usaba: el JOIN por idEvento
--   consumía el único acceso por índice disponible para la tabla,
--   y el filtro terminaba aplicándose fila por fila.
--   Con el compuesto, EXPLAIN reporta Using index (covering index):
--   la consulta se resuelve sin tocar la tabla.
CREATE INDEX idx_reserva_evento_estado ON reserva(idEvento, estado);
CREATE INDEX idx_reserva_estado        ON reserva(estado);
CREATE INDEX idx_zona_dificultad       ON zona(nivel_dificultad);
CREATE INDEX idx_clase_fecha           ON clase(fecha);
CREATE INDEX idx_evento_fecha          ON evento(fecha);


-- ============================================================
-- 9. VISTAS DE CUPOS DISPONIBLES
-- ============================================================
-- Centralizan el cálculo de lugares restantes para que el backend
-- no repita la misma consulta en varios sitios ni el front la
-- calcule por su cuenta.
--
-- Sólo restan las reservas CONFIRMADAS: una pendiente es una
-- intención, no un lugar ocupado, y una cancelada libera el lugar.
-- Contar todos los estados bloquearía cupos realmente libres.
--
-- GREATEST(..., 0) evita mostrar números negativos si por algún
-- error llegaran a existir más reservas que capacidad.

CREATE OR REPLACE VIEW vw_cupos_evento AS
SELECT
    e.idEvento,
    e.titulo,
    e.capacidad,
    COUNT(r.idReserva) AS ocupados,
    GREATEST(e.capacidad - COUNT(r.idReserva), 0) AS disponibles
FROM evento e
LEFT JOIN reserva r
       ON r.idEvento = e.idEvento
      AND r.estado   = 'CONFIRMADA'
GROUP BY e.idEvento, e.titulo, e.capacidad;


CREATE OR REPLACE VIEW vw_cupos_clase AS
SELECT
    c.idClase,
    c.titulo,
    c.capacidad,
    COUNT(r.idReserva) AS ocupados,
    GREATEST(c.capacidad - COUNT(r.idReserva), 0) AS disponibles
FROM clase c
LEFT JOIN reserva r
       ON r.idClase = c.idClase
      AND r.estado  = 'CONFIRMADA'
GROUP BY c.idClase, c.titulo, c.capacidad;


-- ============================================================
-- 10. CONSULTAS DE REFERENCIA PARA EL BACKEND
-- ============================================================

-- ------------------------------------------------------------
-- Estadística de zonas más visitadas
-- (requisito de Probabilidad y Estadística)
--
-- Los alias van en camelCase para que la proyección de Spring
-- Data mapee directo a getNombreZona() / getTotalReservas().
-- Con alias en snake_case el mapeo queda a merced de la
-- conversión implícita y devuelve nulos.
-- ------------------------------------------------------------
-- SELECT z.nombre_zona AS nombreZona, COUNT(r.idReserva) AS totalReservas
-- FROM zona z
-- JOIN evento e  ON e.idZona   = z.idZona
-- JOIN reserva r ON r.idEvento = e.idEvento
-- WHERE r.estado = 'CONFIRMADA'
-- GROUP BY z.idZona, z.nombre_zona
-- ORDER BY totalReservas DESC;

-- ------------------------------------------------------------
-- Zona con su guía, dificultad y coordenadas (mapa del front)
-- LEFT JOIN para que las zonas sin guía también aparezcan.
-- ------------------------------------------------------------
-- SELECT z.idZona, z.nombre_zona, z.ubicacion, z.nivel_dificultad,
--        z.latitud, z.longitud, d.tipo AS deporte, u.nombre AS guia
-- FROM zona z
-- LEFT JOIN guia g     ON g.idGuia     = z.idGuia
-- LEFT JOIN usuario u  ON u.idUsuario  = g.idUsuario
-- LEFT JOIN deporte d  ON d.idDeporte  = z.idDeporte;

-- ------------------------------------------------------------
-- Cupos disponibles en una clase
-- ------------------------------------------------------------
-- SELECT (c.capacidad - COUNT(r.idReserva)) AS cupos_disponibles
-- FROM clase c
-- LEFT JOIN reserva r ON r.idClase = c.idClase AND r.estado = 'CONFIRMADA'
-- WHERE c.idClase = ?
-- GROUP BY c.idClase, c.capacidad;

-- ------------------------------------------------------------
-- Calificación promedio y número de reseñas de una clase
--
-- NO se almacenan como columnas: son valores derivados. Guardarlos
-- desnormalizaría el esquema y quedarían desincronizados en cuanto
-- se agregue o elimine una reseña.
-- ------------------------------------------------------------
-- SELECT AVG(re.calificacion) AS promedio, COUNT(re.idResena) AS total
-- FROM resena re
-- JOIN reserva r ON r.idReserva = re.idReserva
-- WHERE r.idClase = ?;

-- ------------------------------------------------------------
-- Historial de reservas de un explorador
-- ------------------------------------------------------------
-- SELECT r.idReserva, r.estado, r.precio_reserva, r.fecha_reserva,
--        c.titulo AS clase_titulo, e.titulo AS evento_titulo, z.nombre_zona
-- FROM reserva r
-- LEFT JOIN clase c   ON r.idClase  = c.idClase
-- LEFT JOIN evento e  ON r.idEvento = e.idEvento
-- LEFT JOIN zona z    ON e.idZona   = z.idZona
-- JOIN explorador ex  ON r.idExplorador = ex.idExplorador
-- WHERE ex.idUsuario = ?;

-- ------------------------------------------------------------
-- Favoritos de un usuario, con los datos que muestra la tarjeta
-- ------------------------------------------------------------
-- SELECT e.idEvento, e.titulo, e.precio, e.duracion, e.foto_url,
--        z.nombre_zona, z.nivel_dificultad, d.tipo AS deporte,
--        f.fecha AS guardado_el
-- FROM favorito f
-- JOIN evento e   ON e.idEvento  = f.idEvento
-- JOIN zona z     ON z.idZona    = e.idZona
-- JOIN deporte d  ON d.idDeporte = e.idDeporte
-- WHERE f.idUsuario = ?
-- ORDER BY f.fecha DESC;

-- ------------------------------------------------------------
-- Saber si un evento ya está guardado
-- (para pintar el icono lleno o vacío al cargar la tarjeta)
-- ------------------------------------------------------------
-- SELECT EXISTS(
--     SELECT 1 FROM favorito WHERE idUsuario = ? AND idEvento = ?
-- ) AS guardado;

-- ------------------------------------------------------------
-- Cupos antes de confirmar una reserva
-- Si devuelve 0, el backend debe rechazar la reserva.
-- ------------------------------------------------------------
-- SELECT disponibles FROM vw_cupos_evento WHERE idEvento = ?;
-- SELECT disponibles FROM vw_cupos_clase  WHERE idClase  = ?;


-- ============================================================
-- 11. CONEXIÓN
-- ============================================================
-- spring.datasource.url=jdbc:mysql://localhost:3306/horizon_db
-- spring.datasource.username=horizon_user
-- spring.datasource.password=<solicitar a Carlos, no se versiona>
-- spring.jpa.hibernate.ddl-auto=none
-- spring.jpa.hibernate.naming.physical-strategy=org.hibernate.boot.model.naming.PhysicalNamingStrategyStandardImpl
--
-- Si la contraseña contiene $, = o &, NO ponerla en el archivo:
-- Spring interpreta $ como inicio de variable y transmite una
-- cadena distinta. Pasarla como parámetro de arranque:
--   java -jar backend.jar --spring.datasource.password='...'
-- Es además la práctica recomendada: la credencial no queda
-- escrita dentro del artefacto compilado ni del repositorio.
--
-- NOTA: en MySQL, el comodín '%' NO incluye 'localhost'. Si el
-- backend corre en el mismo servidor que la base, hace falta
-- conceder permisos a horizon_user@'localhost' por separado.
-- ============================================================