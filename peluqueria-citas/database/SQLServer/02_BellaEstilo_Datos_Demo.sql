-- BELLA ESTILO - DATOS OPCIONALES PARA PROBAR EL SISTEMA LOCALMENTE
-- Ejecutar DESPUES de 01_BellaEstilo_Estructura.sql.
-- ATENCION: estas cuentas tienen contraseñas PUBLICAS de demostracion.
-- NUNCA ejecutar este archivo en un servidor publico o de produccion.
-- Los hashes son BCrypt compatibles con Spring Security; no se guardan claves en claro.

USE [peluqueria_citas];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- Usuario de recepcion, tres estilistas y cuatro clientes.
INSERT dbo.usuario (id_rol, nombres, apellidos, email, telefono, password_hash)
SELECT r.id_rol, x.nombres, x.apellidos, x.email, x.telefono, x.hash_clave
FROM (VALUES
    (N'ADMINISTRADOR', N'Recepción', N'Bella Estilo', N'recepcion@bellaestilo.pe', N'987000111',
     N'$2b$10$.PN3quV7DmYHHE2XqOu73u8VQghswxOYXZ1t77144EwUWJesr5dX.'),
    (N'ESTILISTA', N'Milagros', N'Ramos', N'milagros@bellaestilo.pe', N'987000222',
     N'$2b$10$dnsMcBcbmFEfhPUiRSqNnOMt6W8RBviHfjhSDYd7cABjJdwIjEviK'),
    (N'ESTILISTA', N'Rosa', N'Salinas', N'rosa@bellaestilo.pe', N'987000222',
     N'$2b$10$dnsMcBcbmFEfhPUiRSqNnOMt6W8RBviHfjhSDYd7cABjJdwIjEviK'),
    (N'ESTILISTA', N'Jimena', N'Tello', N'jimena@bellaestilo.pe', N'987000222',
     N'$2b$10$dnsMcBcbmFEfhPUiRSqNnOMt6W8RBviHfjhSDYd7cABjJdwIjEviK'),
    (N'CLIENTE', N'Valeria', N'Rojas Díaz', N'valeria.rojas@correo.com', N'987654321',
     N'$2b$10$C5DlU5jvrD0AMPVYoNQVQuAm39HzaoFgZnHlGwAPfxszMPxy0bmYG'),
    (N'CLIENTE', N'Jimena', N'Torres', N'jimena.torres@correo.com', N'991223344',
     N'$2b$10$C5DlU5jvrD0AMPVYoNQVQuAm39HzaoFgZnHlGwAPfxszMPxy0bmYG'),
    (N'CLIENTE', N'Rosa', N'Sánchez', N'rosa.sanchez@correo.com', N'977112233',
     N'$2b$10$C5DlU5jvrD0AMPVYoNQVQuAm39HzaoFgZnHlGwAPfxszMPxy0bmYG'),
    (N'CLIENTE', N'Carla', N'Medina', N'carla.medina@correo.com', N'966554433',
     N'$2b$10$C5DlU5jvrD0AMPVYoNQVQuAm39HzaoFgZnHlGwAPfxszMPxy0bmYG')
) AS x(rol, nombres, apellidos, email, telefono, hash_clave)
JOIN dbo.rol r ON r.nombre = x.rol
WHERE NOT EXISTS (SELECT 1 FROM dbo.usuario u WHERE u.email = x.email);

INSERT dbo.cliente (id_usuario)
SELECT u.id_usuario FROM dbo.usuario u
WHERE u.email IN
 (N'valeria.rojas@correo.com', N'jimena.torres@correo.com',
  N'rosa.sanchez@correo.com', N'carla.medina@correo.com')
AND NOT EXISTS (SELECT 1 FROM dbo.cliente c WHERE c.id_usuario = u.id_usuario);

INSERT dbo.estilista (id_usuario, id_sede, especialidad)
SELECT u.id_usuario, s.id_sede, x.especialidad
FROM (VALUES
    (N'milagros@bellaestilo.pe', N'Corte'),
    (N'rosa@bellaestilo.pe', N'Color y tratamientos'),
    (N'jimena@bellaestilo.pe', N'Peinados de evento')
) x(email, especialidad)
JOIN dbo.usuario u ON u.email = x.email
CROSS JOIN (SELECT TOP (1) id_sede FROM dbo.sede ORDER BY id_sede) s
WHERE NOT EXISTS (SELECT 1 FROM dbo.estilista e WHERE e.id_usuario = u.id_usuario);

-- Horarios: lunes a viernes 09:00-19:00; sabados 09:00-17:00.
INSERT dbo.horario_estilista (id_estilista, dia_semana, hora_inicio, hora_fin)
SELECT e.id_usuario, d.dia, CONVERT(TIME(0), '09:00'),
       CASE WHEN d.dia = 6 THEN CONVERT(TIME(0), '17:00') ELSE CONVERT(TIME(0), '19:00') END
FROM dbo.estilista e
JOIN dbo.usuario u ON u.id_usuario = e.id_usuario
CROSS JOIN (VALUES (1),(2),(3),(4),(5),(6)) d(dia)
WHERE u.email IN (N'milagros@bellaestilo.pe', N'rosa@bellaestilo.pe', N'jimena@bellaestilo.pe')
AND NOT EXISTS (
    SELECT 1 FROM dbo.horario_estilista h
    WHERE h.id_estilista = e.id_usuario AND h.dia_semana = d.dia AND h.hora_inicio = '09:00'
);

-- Servicios que puede realizar cada estilista.
INSERT dbo.estilista_servicio (id_estilista, id_servicio)
SELECT u.id_usuario, s.id_servicio
FROM (VALUES
    (N'milagros@bellaestilo.pe', N'Corte de cabello'),
    (N'milagros@bellaestilo.pe', N'Lavado y secado'),
    (N'milagros@bellaestilo.pe', N'Tratamiento capilar'),
    (N'rosa@bellaestilo.pe', N'Tinte y color'),
    (N'rosa@bellaestilo.pe', N'Tratamiento capilar'),
    (N'rosa@bellaestilo.pe', N'Alisado permanente'),
    (N'rosa@bellaestilo.pe', N'Lavado y secado'),
    (N'jimena@bellaestilo.pe', N'Peinado para evento'),
    (N'jimena@bellaestilo.pe', N'Lavado y secado'),
    (N'jimena@bellaestilo.pe', N'Corte de cabello')
) x(email, servicio)
JOIN dbo.usuario u ON u.email = x.email
JOIN dbo.estilista e ON e.id_usuario = u.id_usuario
JOIN dbo.servicio s ON s.nombre = x.servicio
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.estilista_servicio es
    WHERE es.id_estilista = u.id_usuario AND es.id_servicio = s.id_servicio
);

-- Solo agrega citas de ejemplo si aun no hay citas guardadas.
IF NOT EXISTS (SELECT 1 FROM dbo.cita)
BEGIN
    DECLARE @ejemplos TABLE (
        cliente NVARCHAR(120), estilista NVARCHAR(120), dias INT,
        inicio TIME(0), estado NVARCHAR(15), servicio NVARCHAR(80)
    );
    INSERT @ejemplos (cliente, estilista, dias, inicio, estado, servicio) VALUES
        (N'rosa.sanchez@correo.com', N'jimena@bellaestilo.pe', 0, '09:30', N'ATENDIDA', N'Lavado y secado'),
        (N'jimena.torres@correo.com', N'rosa@bellaestilo.pe', 0, '11:00', N'CONFIRMADA', N'Tinte y color'),
        (N'valeria.rojas@correo.com', N'milagros@bellaestilo.pe', 0, '15:00', N'PENDIENTE', N'Corte de cabello'),
        (N'rosa.sanchez@correo.com', N'milagros@bellaestilo.pe', 0, '16:30', N'CONFIRMADA', N'Tratamiento capilar'),
        (N'carla.medina@correo.com', N'jimena@bellaestilo.pe', 0, '18:00', N'CANCELADA', N'Peinado para evento'),
        (N'valeria.rojas@correo.com', N'rosa@bellaestilo.pe', 5, '11:00', N'PENDIENTE', N'Tinte y color'),
        (N'valeria.rojas@correo.com', N'milagros@bellaestilo.pe', 8, '16:30', N'CONFIRMADA', N'Tratamiento capilar'),
        (N'valeria.rojas@correo.com', N'milagros@bellaestilo.pe', -10, '10:00', N'ATENDIDA', N'Corte de cabello'),
        (N'valeria.rojas@correo.com', N'jimena@bellaestilo.pe', -20, '15:00', N'ATENDIDA', N'Peinado para evento'),
        (N'jimena.torres@correo.com', N'rosa@bellaestilo.pe', -12, '09:00', N'ATENDIDA', N'Tinte y color'),
        (N'rosa.sanchez@correo.com', N'milagros@bellaestilo.pe', -6, '12:00', N'AUSENTE', N'Corte de cabello'),
        (N'carla.medina@correo.com', N'rosa@bellaestilo.pe', -3, '14:00', N'CANCELADA', N'Tratamiento capilar');

    INSERT dbo.cita (id_cliente, id_estilista, id_sede, fecha, hora_inicio, hora_fin, estado, total)
    SELECT cli.id_usuario, e.id_usuario, e.id_sede,
           DATEADD(DAY, x.dias, CAST(GETDATE() AS DATE)), x.inicio,
           DATEADD(MINUTE, s.duracion_min, x.inicio), x.estado, s.precio
    FROM @ejemplos x
    JOIN dbo.usuario cli ON cli.email = x.cliente
    JOIN dbo.cliente c ON c.id_usuario = cli.id_usuario
    JOIN dbo.usuario est ON est.email = x.estilista
    JOIN dbo.estilista e ON e.id_usuario = est.id_usuario
    JOIN dbo.servicio s ON s.nombre = x.servicio;

    INSERT dbo.detalle_cita (id_cita, id_servicio, precio_aplicado, duracion_min)
    SELECT c.id_cita, s.id_servicio, s.precio, s.duracion_min
    FROM @ejemplos x
    JOIN dbo.usuario cli ON cli.email = x.cliente
    JOIN dbo.usuario est ON est.email = x.estilista
    JOIN dbo.servicio s ON s.nombre = x.servicio
    JOIN dbo.cita c ON c.id_cliente = cli.id_usuario AND c.id_estilista = est.id_usuario
      AND c.fecha = DATEADD(DAY, x.dias, CAST(GETDATE() AS DATE)) AND c.hora_inicio = x.inicio
    WHERE NOT EXISTS (SELECT 1 FROM dbo.detalle_cita d WHERE d.id_cita = c.id_cita AND d.id_servicio = s.id_servicio);
END;

COMMIT TRANSACTION;

PRINT N'Datos de demostración cargados. NO usar sus claves en producción.';
SELECT (SELECT COUNT(*) FROM dbo.usuario) AS usuarios,
       (SELECT COUNT(*) FROM dbo.estilista) AS estilistas,
       (SELECT COUNT(*) FROM dbo.cliente) AS clientes,
       (SELECT COUNT(*) FROM dbo.cita) AS citas;
GO
