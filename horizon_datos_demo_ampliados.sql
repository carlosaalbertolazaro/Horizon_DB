-- ============================================================
--  HORIZON DB — Datos de demostración ampliados
-- ============================================================
--  Proyecto Integrador — Plataforma de ecoturismo, Chiapas
--  Responsable de BD e infraestructura: Carlos
--
--  Aplicar DESPUÉS de horizon_seeds_v4.sql (usa los idExplorador,
--  idGuia y idUsuario que ese archivo crea).
--      mysql -u root -p horizon_db < horizon_datos_demo_ampliados.sql
--
--  Motivo: los seeds originales dejaban al guía "Pedro Pablo" sin
--  zona ni actividades, y a los demás guías con muy pocas o ninguna
--  reseña, lo que hacía que las gráficas del dashboard del guía
--  (desglose de calificaciones, ganancias por mes) se vieran vacías
--  o poco realistas en las demos.
--
--  Deja ADREDE algunos casos sin cerrar, pensados para demostrarse
--  en vivo:
--    - Una reserva CONFIRMADA sin reseña (idExplorador=3, evento
--      "Rapel Matutino en la Sima") para el flujo "Dejar reseña".
--    - Reservas en estado PENDIENTE para el flujo "Gestionar grupo /
--      aceptar reserva" desde el dashboard del guía.
-- ============================================================

USE horizon_db;

-- ---------- PEDRO PABLO (idGuia=3) estaba sin zona ni actividad ----------
UPDATE guia SET especialidad='Senderismo familiar', experiencia_anios=5,
    descripcion='Guía especializado en rutas familiares de bajo impacto, ideales para principiantes y niños.'
    WHERE idGuia=3;

INSERT INTO zona (idGuia, idDeporte, nombre_zona, ubicacion, nivel_dificultad, descripcion, latitud, longitud)
VALUES (3, 2, 'Mirador de las Nubes', 'Comitán, Chiapas', 'FACIL',
    'Sendero corto y accesible con miradores panorámicos, ideal para familias.', 16.2500000, -92.1330000);
SET @zonaPedro = LAST_INSERT_ID();

-- ---------- ALBERTO (idGuia=4) estaba sin zona ni actividad ----------
INSERT INTO zona (idGuia, idDeporte, nombre_zona, ubicacion, nivel_dificultad, descripcion, latitud, longitud)
VALUES (4, 1, 'Pared del Águila', 'San Cristóbal de las Casas, Chiapas', 'DIFICIL',
        'Ruta de escalada deportiva en roca caliza, con vistas al valle. Ideal para escaladores con experiencia previa.',
        16.7370000, -92.6376000);
SET @zonaAlberto = LAST_INSERT_ID();

INSERT INTO evento (idDeporte, idZona, titulo, descripcion, fecha, duracion, precio, capacidad, foto_url) VALUES
(1, @zonaAlberto, 'Escalada Técnica en el Águila', 'Ruta técnica de dificultad alta, grupo reducido.', '2026-04-18 08:00:00', '6 Horas', 780.00, 6, 'https://images.unsplash.com/photo-1522163182402-834f871fd851?q=80&w=800'),
(1, @zonaAlberto, 'Ruta de Iniciación a la Escalada', 'Primer contacto con la escalada deportiva, equipo incluido.', '2026-05-24 09:00:00', '4 Horas', 550.00, 8, 'https://images.unsplash.com/photo-1522163182402-834f871fd851?q=80&w=800'),
(1, @zonaAlberto, 'Escalada Avanzada Nocturna', 'Ascenso al atardecer con frontales, para escaladores experimentados.', '2026-06-14 17:00:00', '5 Horas', 890.00, 6, 'https://images.unsplash.com/photo-1522163182402-834f871fd851?q=80&w=800'),
(1, @zonaAlberto, 'Escalada de Fin de Semana', 'Sesión de fin de semana para grupos pequeños.', '2026-07-05 08:00:00', '6 Horas', 780.00, 6, 'https://images.unsplash.com/photo-1522163182402-834f871fd851?q=80&w=800'),
(1, @zonaAlberto, 'Escalada Técnica - Agosto', 'Ruta técnica de dificultad alta, grupo reducido.', '2026-08-09 08:00:00', '6 Horas', 780.00, 6, 'https://images.unsplash.com/photo-1522163182402-834f871fd851?q=80&w=800'),
(1, @zonaAlberto, 'Escalada Nocturna - Agosto', 'Ascenso al atardecer con frontales.', '2026-08-22 17:00:00', '5 Horas', 890.00, 6, 'https://images.unsplash.com/photo-1522163182402-834f871fd851?q=80&w=800');

SET @evAbril     = (SELECT idEvento FROM evento WHERE titulo='Escalada Técnica en el Águila' AND idZona=@zonaAlberto);
SET @evMayo      = (SELECT idEvento FROM evento WHERE titulo='Ruta de Iniciación a la Escalada' AND idZona=@zonaAlberto);
SET @evJunioAlb  = (SELECT idEvento FROM evento WHERE titulo='Escalada Avanzada Nocturna' AND idZona=@zonaAlberto);
SET @evJulioAlb  = (SELECT idEvento FROM evento WHERE titulo='Escalada de Fin de Semana' AND idZona=@zonaAlberto);
SET @evAgosto1   = (SELECT idEvento FROM evento WHERE titulo='Escalada Técnica - Agosto' AND idZona=@zonaAlberto);
SET @evAgosto2   = (SELECT idEvento FROM evento WHERE titulo='Escalada Nocturna - Agosto' AND idZona=@zonaAlberto);

INSERT INTO reserva (idExplorador, idEvento, precio_reserva, fecha_reserva, estado) VALUES
(1, @evAbril,   780.00, '2026-04-10 10:00:00', 'CONFIRMADA'),
(2, @evAbril,   780.00, '2026-04-11 12:00:00', 'CONFIRMADA'),
(3, @evMayo,    550.00, '2026-05-15 09:00:00', 'CONFIRMADA'),
(1, @evMayo,    550.00, '2026-05-16 09:30:00', 'CONFIRMADA'),
(2, @evJunioAlb,890.00, '2026-06-05 11:00:00', 'CONFIRMADA'),
(3, @evJulioAlb,780.00, '2026-06-28 08:00:00', 'CONFIRMADA'),
(1, @evJulioAlb,780.00, '2026-06-29 08:30:00', 'CONFIRMADA'),
(2, @evAgosto1, 780.00, '2026-07-18 10:00:00', 'CONFIRMADA'),
(3, @evAgosto2, 890.00, '2026-07-19 10:00:00', 'PENDIENTE');

SET @resAbril1 = (SELECT idReserva FROM reserva WHERE idExplorador=1 AND idEvento=@evAbril);
SET @resAbril2 = (SELECT idReserva FROM reserva WHERE idExplorador=2 AND idEvento=@evAbril);
SET @resMayo1  = (SELECT idReserva FROM reserva WHERE idExplorador=3 AND idEvento=@evMayo);
SET @resJunio1 = (SELECT idReserva FROM reserva WHERE idExplorador=2 AND idEvento=@evJunioAlb);
SET @resJulio1 = (SELECT idReserva FROM reserva WHERE idExplorador=3 AND idEvento=@evJulioAlb);

INSERT INTO resena (idReserva, calificacion, comentario, fecha) VALUES
(@resAbril1, 5, 'Alberto conoce cada agarre de la pared. Explicación técnica excelente y muy paciente con el grupo.', '2026-04-19 12:00:00'),
(@resAbril2, 4, 'Muy buena ruta, aunque empezamos un poco tarde. El equipo estaba en perfecto estado.', '2026-04-19 13:00:00'),
(@resMayo1,  5, 'Perfecta para iniciarse. Me sentí segura todo el tiempo y aprendí muchísimo.', '2026-05-25 10:00:00'),
(@resJunio1, 5, 'La escalada nocturna fue una experiencia increíble, muy bien organizada.', '2026-06-15 09:00:00'),
(@resJulio1, 4, 'Buena sesión, grupo pequeño y buen ambiente. Repetiría.', '2026-07-06 09:00:00');

-- ---------- Actividades pasadas para Pedro Pablo ----------
INSERT INTO evento (idDeporte, idZona, titulo, descripcion, fecha, duracion, precio, capacidad, foto_url) VALUES
(2, @zonaPedro, 'Caminata Familiar al Mirador', 'Ruta accesible de dificultad baja, apta para todas las edades.', '2026-06-08 09:00:00', '3 Horas', 320.00, 12, 'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?q=80&w=800'),
(2, @zonaPedro, 'Mirador al Atardecer', 'Caminata corta con fotografía de paisaje al atardecer.', '2026-08-16 16:00:00', '2 Horas', 280.00, 10, 'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?q=80&w=800');

SET @evPedroPasado = (SELECT idEvento FROM evento WHERE titulo='Caminata Familiar al Mirador' AND idZona=@zonaPedro);
SET @evPedroFuturo = (SELECT idEvento FROM evento WHERE titulo='Mirador al Atardecer' AND idZona=@zonaPedro);

INSERT INTO reserva (idExplorador, idEvento, precio_reserva, fecha_reserva, estado) VALUES
(1, @evPedroPasado, 320.00, '2026-06-01 10:00:00', 'CONFIRMADA'),
(2, @evPedroPasado, 320.00, '2026-06-02 11:00:00', 'CONFIRMADA'),
(1, @evPedroFuturo, 280.00, '2026-07-20 09:00:00', 'PENDIENTE');   -- pendiente futura, para "gestionar grupo"

SET @resPedro1 = (SELECT idReserva FROM reserva WHERE idExplorador=1 AND idEvento=@evPedroPasado);
SET @resPedro2 = (SELECT idReserva FROM reserva WHERE idExplorador=2 AND idEvento=@evPedroPasado);

INSERT INTO resena (idReserva, calificacion, comentario, fecha) VALUES
(@resPedro1, 5, 'Ruta perfecta para ir con niños, Pedro fue muy atento con el grupo.', '2026-06-09 12:00:00'),
(@resPedro2, 4, 'Muy buena vista, aunque el punto de encuentro estaba algo escondido.', '2026-06-09 13:00:00');

-- ---------- CARLOS MENDOZA (idGuia=1): actividad pasada nueva ----------
INSERT INTO evento (idDeporte, idZona, titulo, descripcion, fecha, duracion, precio, capacidad, foto_url) VALUES
(2, 2, 'Ascenso Guiado al Tacaná - Grupo Junio', 'Expedición de un día completo al volcán más alto del sureste.', '2026-06-20 05:00:00', 'Día Completo', 1650.00, 8, 'https://images.unsplash.com/photo-1551632811-561732d1e306?q=80&w=800'),
(1, 3, 'Rapel Matutino en la Sima', 'Sesión de rapel con instrucción básica incluida.', '2026-06-27 07:00:00', '5 Horas', 1200.00, 6, 'https://images.unsplash.com/photo-1522163182402-834f871fd851?q=80&w=800');

SET @evTacanaJunio = (SELECT idEvento FROM evento WHERE titulo='Ascenso Guiado al Tacaná - Grupo Junio');
SET @evSimaJunio = (SELECT idEvento FROM evento WHERE titulo='Rapel Matutino en la Sima');

INSERT INTO reserva (idExplorador, idEvento, precio_reserva, fecha_reserva, estado) VALUES
(2, @evTacanaJunio, 1650.00, '2026-06-10 09:00:00', 'CONFIRMADA'),
(1, @evSimaJunio,   1200.00, '2026-06-18 10:00:00', 'CONFIRMADA'),
(3, @evSimaJunio,   1200.00, '2026-06-19 11:00:00', 'CONFIRMADA'); -- idExplorador 3 = carlos Alberto, queda SIN reseña a propósito

SET @resTacanaJunio = (SELECT idReserva FROM reserva WHERE idExplorador=2 AND idEvento=@evTacanaJunio);
SET @resSimaJunio1  = (SELECT idReserva FROM reserva WHERE idExplorador=1 AND idEvento=@evSimaJunio);

INSERT INTO resena (idReserva, calificacion, comentario, fecha) VALUES
(@resTacanaJunio, 5, 'La cumbre valió cada paso. Carlos conoce el clima de la montaña como nadie.', '2026-06-21 14:00:00'),
(@resSimaJunio1,  4, 'Buena instrucción de rapel, aunque el grupo era un poco grande.', '2026-06-28 10:00:00');

-- Reserva PENDIENTE sobre un evento futuro ya existente (id 2 = Ascenso al Volcán Tacaná),
-- para demostrar en vivo "aceptar / gestionar grupo" desde el dashboard del guía.
INSERT INTO reserva (idExplorador, idEvento, precio_reserva, fecha_reserva, estado) VALUES
(3, 2, 1650.00, '2026-07-19 15:00:00', 'PENDIENTE');

-- ---------- LUCÍA (idGuia=2): una reseña más ----------
INSERT INTO evento (idDeporte, idZona, titulo, descripcion, fecha, duracion, precio, capacidad, foto_url) VALUES
(4, 1, 'Kayak de Río - Grupo de Julio', 'Recorrido guiado en aguas tranquilas, apto para principiantes.', '2026-07-08 08:00:00', '3 Horas', 700.00, 10, 'https://images.unsplash.com/photo-1502680390469-be75c86b636f?q=80&w=800');

SET @evKayakJulio = (SELECT idEvento FROM evento WHERE titulo='Kayak de Río - Grupo de Julio');

INSERT INTO reserva (idExplorador, idEvento, precio_reserva, fecha_reserva, estado) VALUES
(2, @evKayakJulio, 700.00, '2026-06-30 09:00:00', 'CONFIRMADA');

SET @resKayakJulio = (SELECT idReserva FROM reserva WHERE idExplorador=2 AND idEvento=@evKayakJulio);

INSERT INTO resena (idReserva, calificacion, comentario, fecha) VALUES
(@resKayakJulio, 5, 'Lucía transmite mucha confianza en el agua, ideal para quienes recién empiezan.', '2026-07-09 11:00:00');

-- ---------- Reserva de CLASE confirmada y sin reseña (probar flujo con clases) ----------
INSERT INTO reserva (idExplorador, idClase, precio_reserva, fecha_reserva, estado) VALUES
(1, 2, 750.00, '2026-06-15 10:00:00', 'CONFIRMADA'); -- clase 2 = Escalada en roca para principiantes (Carlos Mendoza)

-- ---------- FAVORITOS: más rutas guardadas ----------
INSERT INTO favorito (idUsuario, idEvento, fecha) VALUES
(6, 1, '2026-07-10 09:00:00'),               -- carlos Alberto guarda Cañón del Sumidero
(6, @evTacanaJunio, '2026-07-15 09:00:00'),  -- y el Tacaná de junio
(3, 6, '2026-07-05 09:00:00'),               -- Alex Montoya guarda Lagunas de Colón
(4, 5, '2026-07-06 09:00:00');               -- Laura Sánchez guarda El Chiflón

-- Verificación
SELECT z.idGuia, COUNT(DISTINCT r.idReserva) reservas, COUNT(DISTINCT res.idResena) resenas
FROM zona z
LEFT JOIN evento e ON e.idZona = z.idZona
LEFT JOIN reserva r ON r.idEvento = e.idEvento
LEFT JOIN resena res ON res.idReserva = r.idReserva
GROUP BY z.idGuia;
