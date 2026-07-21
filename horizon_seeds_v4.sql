-- ============================================================
--  HORIZON DB - DATOS SEMILLA (compatible con horizon_db_v4.sql)
-- ============================================================
--  Este archivo NO crea ni modifica tablas. Sólo inserta datos
--  de prueba para poder desarrollar y demostrar el sistema con
--  contenido real en pantalla.
--
--  Ejecutar DESPUÉS del esquema:
--      mysql -u root -p < horizon_db_v4.sql
--      mysql -u root -p < horizon_seeds_v4.sql
--
--  Para reiniciar sólo los datos sin tocar el esquema, volver a
--  ejecutar este archivo: empieza limpiando las tablas.
-- ============================================================

USE horizon_db;

-- ============================================================
--  LIMPIEZA
-- ============================================================
-- Orden inverso a las dependencias. Se desactiva la verificación
-- de llaves foráneas durante el TRUNCATE porque MySQL la aplica
-- incluso cuando la tabla queda vacía.
-- rol y deporte NO se tocan: los llena el esquema.

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE documento_guia;
TRUNCATE TABLE resena;
TRUNCATE TABLE reserva;
TRUNCATE TABLE evento;
TRUNCATE TABLE clase;
TRUNCATE TABLE zona;
TRUNCATE TABLE explorador;
TRUNCATE TABLE guia;
TRUNCATE TABLE usuario;
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
--  USUARIOS
-- ============================================================
-- IMPORTANTE: password_hash NO admite texto plano.
-- AuthService compara con BCryptPasswordEncoder; si aquí se
-- guardara la contraseña sin hashear, el login fallaría siempre.
--
-- El hash de abajo corresponde a la contraseña:  password123
-- Formato $2a$ con 10 rondas, compatible con Spring Security.
-- Todas las cuentas de prueba comparten esa contraseña.
--
-- idRol -> 1 = EXPLORADOR, 2 = GUIA, 3 = ADMIN

INSERT INTO usuario (idRol, nombre, correo, password_hash, foto_url) VALUES
(2, 'Carlos Mendoza', 'carlos@horizon.com',
 '$2a$10$Q7MoS4zZAuOFBAf1xwnUbeTeOFaIfc5XVvFS9lSR371ph5tveaHRO',
 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200'),
(2, 'Lucía Ramírez', 'lucia@horizon.com',
 '$2a$10$Q7MoS4zZAuOFBAf1xwnUbeTeOFaIfc5XVvFS9lSR371ph5tveaHRO',
 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=200'),
(1, 'Alex Montoya', 'alex@horizon.com',
 '$2a$10$Q7MoS4zZAuOFBAf1xwnUbeTeOFaIfc5XVvFS9lSR371ph5tveaHRO',
 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200'),
(1, 'Laura Sánchez', 'laura@horizon.com',
 '$2a$10$Q7MoS4zZAuOFBAf1xwnUbeTeOFaIfc5XVvFS9lSR371ph5tveaHRO',
 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?q=80&w=200'),
(3, 'Admin Horizon', 'admin@horizon.com',
 '$2a$10$Q7MoS4zZAuOFBAf1xwnUbeTeOFaIfc5XVvFS9lSR371ph5tveaHRO',
 NULL);

-- Perfiles extendidos -> idGuia 1 = Carlos, 2 = Lucía
INSERT INTO guia (idUsuario, especialidad, experiencia_anios, descripcion, foto_url) VALUES
(1, 'Alta montaña y senderismo', 8,
 'Guía certificado con ocho años liderando expediciones en la Sierra Madre de Chiapas. Especialista en flora local y en orientación sin GPS.',
 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200'),
(2, 'Kayak y deportes acuáticos', 5,
 'Instructora de kayak certificada. Cinco años recorriendo los ríos, cañones y lagunas de Chiapas.',
 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=200');

-- Perfiles extendidos -> idExplorador 1 = Alex, 2 = Laura
INSERT INTO explorador (idUsuario, nivel, foto_url) VALUES
(3, 'INTERMEDIO', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200'),
(4, 'PRINCIPIANTE', 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?q=80&w=200');

-- ============================================================
--  ZONAS  (pines del mapa interactivo)
-- ============================================================
-- nivel_dificultad se guarda SIN acento y en MAYÚSCULAS, según
-- la convención documentada en el esquema. El front normaliza
-- antes de comparar con sus botones de filtro.
--
-- idDeporte -> 1 Escalada, 2 Senderismo, 3 Pesca, 4 Kayak

INSERT INTO zona (idGuia, idDeporte, nombre_zona, ubicacion, nivel_dificultad, descripcion, latitud, longitud) VALUES
(2, 4, 'Cañón del Sumidero', 'Chiapa de Corzo, Chiapas', 'FACIL',
 'Recorrido en kayak por el cañón, entre paredes que alcanzan los mil metros de altura.',
 16.8222000, -93.0784000),
(1, 2, 'Volcán Tacaná', 'Unión Juárez, Chiapas', 'DIFICIL',
 'Ascenso al pico más alto del sureste mexicano, a 4092 metros sobre el nivel del mar.',
 15.1333000, -92.1000000),
(1, 1, 'Sima de las Cotorras', 'Ocozocoautla, Chiapas', 'MEDIO',
 'Descenso y escalada en un hundimiento natural de 160 metros de diámetro, hogar de miles de pericos.',
 16.8044000, -93.4735000),
(NULL, 3, 'Lagos de Montebello', 'La Trinitaria, Chiapas', 'FACIL',
 'Pesca deportiva y navegación entre 59 lagunas de aguas de colores cambiantes.',
 16.1097000, -91.6742000),
(1, 2, 'Cascadas El Chiflón', 'Tzimol, Chiapas', 'MEDIO',
 'Senderismo hasta la cascada Velo de Novia, con 120 metros de caída.',
 16.0089000, -92.2611000),
(2, 4, 'Lagunas de Colón', 'Comalapa, Chiapas', 'FACIL',
 'Sistema de lagunas y manantiales de agua cristalina, ideal para iniciarse en kayak.',
 15.7333000, -92.1500000);

-- ============================================================
--  EVENTOS  (tarjetas del catálogo de actividades)
-- ============================================================

INSERT INTO evento (idDeporte, idZona, titulo, descripcion, fecha, duracion, precio, capacidad, foto_url) VALUES
(4, 1, 'Travesía en kayak por el Cañón del Sumidero',
 'Jornada completa remando entre los acantilados del cañón, con paradas en las cascadas y avistamiento de fauna.',
 '2026-08-15 07:00:00', '6 Horas', 850.00, 12,
 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?q=80&w=800'),
(2, 2, 'Ascenso al Volcán Tacaná',
 'Expedición de alta montaña para excursionistas con experiencia previa en altitud.',
 '2026-08-22 05:00:00', 'Día Completo', 1650.00, 8,
 'https://images.unsplash.com/photo-1551632811-561732d1e306?q=80&w=800'),
(1, 3, 'Rapel y escalada en la Sima de las Cotorras',
 'Descenso de 140 metros en rapel y ascenso asistido, con vista a las pinturas rupestres.',
 '2026-08-29 08:00:00', '5 Horas', 1200.00, 10,
 'https://images.unsplash.com/photo-1522163182402-834f871fd851?q=80&w=800'),
(3, 4, 'Pesca deportiva en Lagos de Montebello',
 'Salida de pesca al amanecer entre las lagunas, con equipo incluido y desayuno a la orilla.',
 '2026-09-05 06:30:00', '4 Horas', 620.00, 15,
 'https://images.unsplash.com/photo-1516132006923-6cf348e5dee2?q=80&w=800'),
(2, 5, 'Sendero de las cinco cascadas, El Chiflón',
 'Caminata guiada por el sendero completo hasta el mirador del Velo de Novia.',
 '2026-09-12 08:00:00', '3 Horas', 450.00, 20,
 'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?q=80&w=800'),
(4, 6, 'Kayak al atardecer en Lagunas de Colón',
 'Recorrido tranquilo en aguas cristalinas, pensado para principiantes y familias.',
 '2026-09-19 16:00:00', '2 Horas', 380.00, 14,
 'https://images.unsplash.com/photo-1502680390469-be75c86b636f?q=80&w=800');

-- ============================================================
--  CLASES  (impartidas por un guía, sin zona asignada)
-- ============================================================

INSERT INTO clase (idGuia, idDeporte, titulo, descripcion, ubicacion, fecha, duracion, precio, capacidad, foto_url) VALUES
(2, 4, 'Iniciación al kayak',
 'Clase básica de técnica de remo, seguridad y auto-rescate. No se requiere experiencia previa.',
 'Embarcadero Cahuaré, Chiapa de Corzo',
 '2026-08-10 09:00:00', '3 Horas', 600.00, 6,
 'https://images.unsplash.com/photo-1585091352626-2e0f1d1a0d84?q=80&w=800'),
(1, 1, 'Escalada en roca para principiantes',
 'Fundamentos de escalada deportiva: nudos, aseguramiento y primeras vías de dificultad baja.',
 'Sima de las Cotorras, Ocozocoautla',
 '2026-08-17 08:00:00', '4 Horas', 750.00, 5,
 'https://images.unsplash.com/photo-1522163182402-834f871fd851?q=80&w=800'),
(1, 2, 'Orientación y lectura de mapa en campo',
 'Uso de brújula, curvas de nivel y navegación sin GPS aplicada a terreno real.',
 'Reserva El Ocote, Ocozocoautla',
 '2026-08-24 07:30:00', '5 Horas', 520.00, 10,
 'https://images.unsplash.com/photo-1454496522488-7a8e488e8606?q=80&w=800');

-- ============================================================
--  RESERVAS
-- ============================================================
-- Regla del esquema: (idClase IS NULL) XOR (idEvento IS NULL).
-- Cada fila apunta a UNA clase o a UN evento, nunca a ambos.
--
-- precio_reserva copia el precio vigente de la actividad, tal
-- como especifica el esquema: si la actividad cambia de precio,
-- la reserva histórica conserva lo que el usuario pagó.

INSERT INTO reserva (idExplorador, idClase, idEvento, precio_reserva, estado) VALUES
(1, NULL, 1, 850.00,  'CONFIRMADA'),
(1, NULL, 3, 1200.00, 'PENDIENTE'),
(1, 1,    NULL, 600.00, 'CONFIRMADA'),
(1, NULL, 5, 450.00,  'CONFIRMADA'),
(2, NULL, 1, 850.00,  'CONFIRMADA'),
(2, 2,    NULL, 750.00, 'PENDIENTE'),
(2, NULL, 4, 620.00,  'CANCELADA');

-- ============================================================
--  RESEÑAS
-- ============================================================
-- Sólo sobre reservas CONFIRMADAS (1, 3, 4 y 5).
-- calificacion válida: 1 a 5.

INSERT INTO resena (idReserva, calificacion, comentario) VALUES
(1, 5, 'Experiencia increíble. La guía conoce cada rincón del cañón y explicó todo con muchísima paciencia.'),
(3, 4, 'Muy buena clase de introducción. El equipo estaba en excelente estado y el grupo fue pequeño.'),
(4, 5, 'El sendero está bien señalizado y la vista del Velo de Novia vale cada paso.'),
(5, 5, 'Repetiría sin dudarlo. Amaneció nublado y aun así el paisaje fue espectacular.');

-- ============================================================
--  DOCUMENTOS DE LOS GUÍAS
-- ============================================================
-- URLs de ejemplo. En producción apuntan a la carpeta privada
-- de S3 y devuelven AccessDenied al abrirlas directamente.

INSERT INTO documento_guia (idGuia, tipo, url) VALUES
(1, 'INE',           'https://horizon-docs-privado.s3.amazonaws.com/guias/1/ine.pdf'),
(1, 'CERTIFICACION', 'https://horizon-docs-privado.s3.amazonaws.com/guias/1/wfr.pdf'),
(1, 'CERTIFICACION', 'https://horizon-docs-privado.s3.amazonaws.com/guias/1/alta-montana.pdf'),
(2, 'INE',           'https://horizon-docs-privado.s3.amazonaws.com/guias/2/ine.pdf'),
(2, 'CERTIFICACION', 'https://horizon-docs-privado.s3.amazonaws.com/guias/2/kayak-nivel2.pdf');

-- ============================================================
--  VERIFICACIÓN
-- ============================================================

SELECT 'usuario'        AS tabla, COUNT(*) AS registros FROM usuario
UNION ALL SELECT 'guia',           COUNT(*) FROM guia
UNION ALL SELECT 'explorador',     COUNT(*) FROM explorador
UNION ALL SELECT 'zona',           COUNT(*) FROM zona
UNION ALL SELECT 'evento',         COUNT(*) FROM evento
UNION ALL SELECT 'clase',          COUNT(*) FROM clase
UNION ALL SELECT 'reserva',        COUNT(*) FROM reserva
UNION ALL SELECT 'resena',         COUNT(*) FROM resena
UNION ALL SELECT 'documento_guia', COUNT(*) FROM documento_guia;
