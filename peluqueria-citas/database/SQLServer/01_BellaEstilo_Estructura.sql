-- BELLA ESTILO - BASE DE DATOS PARA MICROSOFT SQL SERVER
-- Ejecutar en una ventana de consulta de SQL Server Management Studio 22.
-- Este script crea la base si falta; NO borra tablas ni datos existentes.
-- Requiere SQL Server (motor de base de datos), no solo SSMS.

USE [master];
GO
IF DB_ID(N'peluqueria_citas') IS NULL
    CREATE DATABASE [peluqueria_citas];
GO
USE [peluqueria_citas];
GO
SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.rol', N'U') IS NULL
CREATE TABLE dbo.rol (
    id_rol INT IDENTITY(1,1) NOT NULL CONSTRAINT pk_rol PRIMARY KEY,
    nombre NVARCHAR(20) NOT NULL CONSTRAINT uq_rol_nombre UNIQUE
);

IF OBJECT_ID(N'dbo.sede', N'U') IS NULL
CREATE TABLE dbo.sede (
    id_sede BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT pk_sede PRIMARY KEY,
    nombre NVARCHAR(80) NOT NULL,
    direccion NVARCHAR(150) NOT NULL,
    telefono NVARCHAR(20) NULL
);

IF OBJECT_ID(N'dbo.usuario', N'U') IS NULL
CREATE TABLE dbo.usuario (
    id_usuario BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT pk_usuario PRIMARY KEY,
    id_rol INT NOT NULL,
    nombres NVARCHAR(80) NOT NULL,
    apellidos NVARCHAR(80) NOT NULL,
    email NVARCHAR(120) NOT NULL CONSTRAINT uq_usuario_email UNIQUE,
    telefono NVARCHAR(20) NOT NULL,
    password_hash NVARCHAR(100) NOT NULL,
    activo BIT NOT NULL CONSTRAINT df_usuario_activo DEFAULT (1),
    fecha_registro DATETIME2(3) NOT NULL CONSTRAINT df_usuario_registro DEFAULT (SYSDATETIME()),
    ultimo_acceso DATETIME2(3) NULL,
    CONSTRAINT fk_usuario_rol FOREIGN KEY (id_rol) REFERENCES dbo.rol(id_rol)
);

IF OBJECT_ID(N'dbo.cliente', N'U') IS NULL
CREATE TABLE dbo.cliente (
    id_usuario BIGINT NOT NULL CONSTRAINT pk_cliente PRIMARY KEY,
    acepta_whatsapp BIT NOT NULL CONSTRAINT df_cliente_whatsapp DEFAULT (1),
    acepta_correo BIT NOT NULL CONSTRAINT df_cliente_correo DEFAULT (1),
    observaciones NVARCHAR(200) NULL,
    CONSTRAINT fk_cliente_usuario FOREIGN KEY (id_usuario) REFERENCES dbo.usuario(id_usuario)
);

IF OBJECT_ID(N'dbo.estilista', N'U') IS NULL
CREATE TABLE dbo.estilista (
    id_usuario BIGINT NOT NULL CONSTRAINT pk_estilista PRIMARY KEY,
    id_sede BIGINT NOT NULL,
    especialidad NVARCHAR(80) NOT NULL,
    CONSTRAINT fk_estilista_usuario FOREIGN KEY (id_usuario) REFERENCES dbo.usuario(id_usuario),
    CONSTRAINT fk_estilista_sede FOREIGN KEY (id_sede) REFERENCES dbo.sede(id_sede)
);

IF OBJECT_ID(N'dbo.horario_estilista', N'U') IS NULL
CREATE TABLE dbo.horario_estilista (
    id_horario BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT pk_horario PRIMARY KEY,
    id_estilista BIGINT NOT NULL,
    dia_semana INT NOT NULL,
    hora_inicio TIME(0) NOT NULL,
    hora_fin TIME(0) NOT NULL,
    CONSTRAINT ck_horario_dia CHECK (dia_semana BETWEEN 1 AND 7),
    CONSTRAINT ck_horario_horas CHECK (hora_fin > hora_inicio),
    CONSTRAINT uq_horario UNIQUE (id_estilista, dia_semana, hora_inicio),
    CONSTRAINT fk_horario_estilista FOREIGN KEY (id_estilista) REFERENCES dbo.estilista(id_usuario)
);

IF OBJECT_ID(N'dbo.categoria_servicio', N'U') IS NULL
CREATE TABLE dbo.categoria_servicio (
    id_categoria BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT pk_categoria PRIMARY KEY,
    nombre NVARCHAR(50) NOT NULL CONSTRAINT uq_categoria_nombre UNIQUE
);

IF OBJECT_ID(N'dbo.servicio', N'U') IS NULL
CREATE TABLE dbo.servicio (
    id_servicio BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT pk_servicio PRIMARY KEY,
    id_categoria BIGINT NOT NULL,
    nombre NVARCHAR(80) NOT NULL,
    descripcion NVARCHAR(200) NULL,
    precio DECIMAL(12,2) NOT NULL,
    duracion_min INT NOT NULL,
    activo BIT NOT NULL CONSTRAINT df_servicio_activo DEFAULT (1),
    CONSTRAINT ck_servicio_precio CHECK (precio >= 0),
    CONSTRAINT ck_servicio_duracion CHECK (duracion_min > 0),
    CONSTRAINT fk_servicio_categoria FOREIGN KEY (id_categoria) REFERENCES dbo.categoria_servicio(id_categoria)
);

IF OBJECT_ID(N'dbo.estilista_servicio', N'U') IS NULL
CREATE TABLE dbo.estilista_servicio (
    id_estilista BIGINT NOT NULL,
    id_servicio BIGINT NOT NULL,
    CONSTRAINT pk_estilista_servicio PRIMARY KEY (id_estilista, id_servicio),
    CONSTRAINT fk_es_estilista FOREIGN KEY (id_estilista) REFERENCES dbo.estilista(id_usuario),
    CONSTRAINT fk_es_servicio FOREIGN KEY (id_servicio) REFERENCES dbo.servicio(id_servicio)
);

IF OBJECT_ID(N'dbo.cita', N'U') IS NULL
CREATE TABLE dbo.cita (
    id_cita BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT pk_cita PRIMARY KEY,
    id_cliente BIGINT NOT NULL,
    id_estilista BIGINT NOT NULL,
    id_sede BIGINT NOT NULL,
    fecha DATE NOT NULL,
    hora_inicio TIME(0) NOT NULL,
    hora_fin TIME(0) NOT NULL,
    estado NVARCHAR(15) NOT NULL CONSTRAINT df_cita_estado DEFAULT (N'PENDIENTE'),
    total DECIMAL(12,2) NOT NULL,
    motivo_cancelacion NVARCHAR(200) NULL,
    fecha_creacion DATETIME2(3) NOT NULL CONSTRAINT df_cita_creacion DEFAULT (SYSDATETIME()),
    CONSTRAINT ck_cita_horas CHECK (hora_fin > hora_inicio),
    CONSTRAINT ck_cita_total CHECK (total >= 0),
    CONSTRAINT ck_cita_estado CHECK (estado IN
      (N'PENDIENTE', N'CONFIRMADA', N'CANCELADA', N'ATENDIDA', N'AUSENTE')),
    CONSTRAINT fk_cita_cliente FOREIGN KEY (id_cliente) REFERENCES dbo.cliente(id_usuario),
    CONSTRAINT fk_cita_estilista FOREIGN KEY (id_estilista) REFERENCES dbo.estilista(id_usuario),
    CONSTRAINT fk_cita_sede FOREIGN KEY (id_sede) REFERENCES dbo.sede(id_sede)
);

-- Permite reutilizar un inicio de horario si la cita anterior fue CANCELADA.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.cita') AND name = N'ux_cita_slot_activo')
    CREATE UNIQUE INDEX ux_cita_slot_activo
    ON dbo.cita (id_estilista, fecha, hora_inicio) WHERE estado <> N'CANCELADA';

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.cita') AND name = N'ix_cita_cliente_fecha')
    CREATE INDEX ix_cita_cliente_fecha ON dbo.cita (id_cliente, fecha);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.cita') AND name = N'ix_cita_fecha_estado')
    CREATE INDEX ix_cita_fecha_estado ON dbo.cita (fecha, estado);

IF OBJECT_ID(N'dbo.detalle_cita', N'U') IS NULL
CREATE TABLE dbo.detalle_cita (
    id_cita BIGINT NOT NULL,
    id_servicio BIGINT NOT NULL,
    precio_aplicado DECIMAL(12,2) NOT NULL,
    duracion_min INT NOT NULL,
    CONSTRAINT pk_detalle_cita PRIMARY KEY (id_cita, id_servicio),
    CONSTRAINT fk_detalle_cita FOREIGN KEY (id_cita) REFERENCES dbo.cita(id_cita),
    CONSTRAINT fk_detalle_servicio FOREIGN KEY (id_servicio) REFERENCES dbo.servicio(id_servicio)
);

IF OBJECT_ID(N'dbo.notificacion', N'U') IS NULL
CREATE TABLE dbo.notificacion (
    id_notificacion BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT pk_notificacion PRIMARY KEY,
    id_cita BIGINT NOT NULL,
    tipo NVARCHAR(20) NOT NULL,
    canal NVARCHAR(10) NOT NULL,
    mensaje NVARCHAR(300) NOT NULL,
    fecha_programada DATETIME2(3) NOT NULL,
    fecha_envio DATETIME2(3) NULL,
    estado_envio NVARCHAR(10) NOT NULL CONSTRAINT df_notificacion_estado DEFAULT (N'PENDIENTE'),
    intentos INT NOT NULL CONSTRAINT df_notificacion_intentos DEFAULT (0),
    CONSTRAINT ck_notificacion_tipo CHECK (tipo IN
      (N'REGISTRO', N'CONFIRMACION', N'RECORDATORIO', N'CANCELACION', N'REPROGRAMACION')),
    CONSTRAINT ck_notificacion_canal CHECK (canal IN (N'WHATSAPP', N'CORREO')),
    CONSTRAINT ck_notificacion_estado CHECK (estado_envio IN (N'PENDIENTE', N'ENVIADA', N'FALLIDA')),
    CONSTRAINT fk_notif_cita FOREIGN KEY (id_cita) REFERENCES dbo.cita(id_cita)
);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.notificacion') AND name = N'ix_notif_pendientes')
    CREATE INDEX ix_notif_pendientes ON dbo.notificacion (estado_envio, fecha_programada);

IF OBJECT_ID(N'dbo.auditoria', N'U') IS NULL
CREATE TABLE dbo.auditoria (
    id_auditoria BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT pk_auditoria PRIMARY KEY,
    id_usuario BIGINT NULL,
    accion NVARCHAR(50) NOT NULL,
    entidad NVARCHAR(40) NOT NULL,
    id_entidad BIGINT NULL,
    fecha DATETIME2(3) NOT NULL CONSTRAINT df_auditoria_fecha DEFAULT (SYSDATETIME()),
    ip NVARCHAR(45) NULL,
    CONSTRAINT fk_audit_usuario FOREIGN KEY (id_usuario) REFERENCES dbo.usuario(id_usuario)
);

-- Catálogos iniciales; este script se puede ejecutar nuevamente sin duplicarlos.
IF NOT EXISTS (SELECT 1 FROM dbo.rol WHERE nombre = N'CLIENTE')
    INSERT dbo.rol (nombre) VALUES (N'CLIENTE');
IF NOT EXISTS (SELECT 1 FROM dbo.rol WHERE nombre = N'ESTILISTA')
    INSERT dbo.rol (nombre) VALUES (N'ESTILISTA');
IF NOT EXISTS (SELECT 1 FROM dbo.rol WHERE nombre = N'ADMINISTRADOR')
    INSERT dbo.rol (nombre) VALUES (N'ADMINISTRADOR');

IF NOT EXISTS (SELECT 1 FROM dbo.sede WHERE nombre = N'Bella Estilo - Sede principal')
    INSERT dbo.sede (nombre, direccion, telefono)
    VALUES (N'Bella Estilo - Sede principal', N'Dirección de demostración', NULL);

IF NOT EXISTS (SELECT 1 FROM dbo.categoria_servicio WHERE nombre = N'Corte')
    INSERT dbo.categoria_servicio (nombre) VALUES (N'Corte');
IF NOT EXISTS (SELECT 1 FROM dbo.categoria_servicio WHERE nombre = N'Color')
    INSERT dbo.categoria_servicio (nombre) VALUES (N'Color');
IF NOT EXISTS (SELECT 1 FROM dbo.categoria_servicio WHERE nombre = N'Peinado')
    INSERT dbo.categoria_servicio (nombre) VALUES (N'Peinado');
IF NOT EXISTS (SELECT 1 FROM dbo.categoria_servicio WHERE nombre = N'Tratamiento')
    INSERT dbo.categoria_servicio (nombre) VALUES (N'Tratamiento');

INSERT dbo.servicio (id_categoria, nombre, descripcion, precio, duracion_min, activo)
SELECT c.id_categoria, x.nombre, x.descripcion, x.precio, x.minutos, x.activo
FROM (VALUES
    (N'Corte', N'Corte de cabello', N'Corte con estilista a elección', 35.00, 40, 1),
    (N'Color', N'Tinte y color', N'Incluye lavado', 120.00, 90, 1),
    (N'Peinado', N'Peinado para evento', N'Reservar con 24 h de anticipación', 80.00, 60, 1),
    (N'Tratamiento', N'Tratamiento capilar', N'Hidratación profunda', 65.00, 50, 1),
    (N'Tratamiento', N'Alisado permanente', N'Consultar disponibilidad', 180.00, 120, 0),
    (N'Peinado', N'Lavado y secado', N'Incluye masaje capilar', 25.00, 30, 1)
) AS x(categoria, nombre, descripcion, precio, minutos, activo)
JOIN dbo.categoria_servicio c ON c.nombre = x.categoria
WHERE NOT EXISTS (SELECT 1 FROM dbo.servicio s WHERE s.nombre = x.nombre);

PRINT N'Base peluqueria_citas creada/revisada. Tablas y catálogos disponibles.';
SELECT name AS tabla FROM sys.tables ORDER BY name;
GO
