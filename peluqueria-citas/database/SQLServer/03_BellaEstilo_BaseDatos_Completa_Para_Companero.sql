-- Bella Estilo - copia completa para instalar en OTRA computadora.
-- Contiene tablas, restricciones, indices y todos los datos exportados.
-- ATENCION: ejecutar SOLO en una instancia que NO tenga la base peluqueria_citas.
-- NO ejecutar sobre tu base actual ni junto a los scripts 01 y 02.
-- El usuario SQL app_citas debe crearse por separado en el servidor destino.
-- El archivo original del exportador se conserva intacto en esta carpeta.
USE [master];
GO
CREATE DATABASE [peluqueria_citas];
GO
USE [peluqueria_citas];
GO
/****** Objeto: Table [dbo].[auditoria] Fecha de script: 21/11/2026 04:02:24 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[auditoria](
	[id_auditoria] [bigint] IDENTITY(1,1) NOT NULL,
	[id_usuario] [bigint] NULL,
	[accion] [nvarchar](50) NOT NULL,
	[entidad] [nvarchar](40) NOT NULL,
	[id_entidad] [bigint] NULL,
	[fecha] [datetime2](3) NOT NULL,
	[ip] [nvarchar](45) NULL,
 CONSTRAINT [pk_auditoria] PRIMARY KEY CLUSTERED 
(
	[id_auditoria] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[categoria_servicio] Fecha de script: 21/11/2026 04:02:24 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[categoria_servicio](
	[id_categoria] [bigint] IDENTITY(1,1) NOT NULL,
	[nombre] [nvarchar](50) NOT NULL,
 CONSTRAINT [pk_categoria] PRIMARY KEY CLUSTERED 
(
	[id_categoria] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[cita] Fecha de script: 21/11/2026 04:02:24 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[cita](
	[id_cita] [bigint] IDENTITY(1,1) NOT NULL,
	[id_cliente] [bigint] NOT NULL,
	[id_estilista] [bigint] NOT NULL,
	[id_sede] [bigint] NOT NULL,
	[fecha] [date] NOT NULL,
	[hora_inicio] [time](0) NOT NULL,
	[hora_fin] [time](0) NOT NULL,
	[estado] [nvarchar](15) NOT NULL,
	[total] [decimal](12, 2) NOT NULL,
	[motivo_cancelacion] [nvarchar](200) NULL,
	[fecha_creacion] [datetime2](3) NOT NULL,
 CONSTRAINT [pk_cita] PRIMARY KEY CLUSTERED 
(
	[id_cita] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[cliente] Fecha de script: 21/11/2026 04:02:24 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[cliente](
	[id_usuario] [bigint] NOT NULL,
	[acepta_whatsapp] [bit] NOT NULL,
	[acepta_correo] [bit] NOT NULL,
	[observaciones] [nvarchar](200) NULL,
 CONSTRAINT [pk_cliente] PRIMARY KEY CLUSTERED 
(
	[id_usuario] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[detalle_cita] Fecha de script: 21/11/2026 04:02:24 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[detalle_cita](
	[id_cita] [bigint] NOT NULL,
	[id_servicio] [bigint] NOT NULL,
	[precio_aplicado] [decimal](12, 2) NOT NULL,
	[duracion_min] [int] NOT NULL,
 CONSTRAINT [pk_detalle_cita] PRIMARY KEY CLUSTERED 
(
	[id_cita] ASC,
	[id_servicio] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[estilista] Fecha de script: 21/11/2026 04:02:24 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[estilista](
	[id_usuario] [bigint] NOT NULL,
	[id_sede] [bigint] NOT NULL,
	[especialidad] [nvarchar](80) NOT NULL,
 CONSTRAINT [pk_estilista] PRIMARY KEY CLUSTERED 
(
	[id_usuario] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[estilista_servicio] Fecha de script: 21/11/2026 04:02:24 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[estilista_servicio](
	[id_estilista] [bigint] NOT NULL,
	[id_servicio] [bigint] NOT NULL,
 CONSTRAINT [pk_estilista_servicio] PRIMARY KEY CLUSTERED 
(
	[id_estilista] ASC,
	[id_servicio] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[horario_estilista] Fecha de script: 21/11/2026 04:02:24 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[horario_estilista](
	[id_horario] [bigint] IDENTITY(1,1) NOT NULL,
	[id_estilista] [bigint] NOT NULL,
	[dia_semana] [int] NOT NULL,
	[hora_inicio] [time](0) NOT NULL,
	[hora_fin] [time](0) NOT NULL,
 CONSTRAINT [pk_horario] PRIMARY KEY CLUSTERED 
(
	[id_horario] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[notificacion] Fecha de script: 21/11/2026 04:02:24 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[notificacion](
	[id_notificacion] [bigint] IDENTITY(1,1) NOT NULL,
	[id_cita] [bigint] NOT NULL,
	[tipo] [nvarchar](20) NOT NULL,
	[canal] [nvarchar](10) NOT NULL,
	[mensaje] [nvarchar](300) NOT NULL,
	[fecha_programada] [datetime2](3) NOT NULL,
	[fecha_envio] [datetime2](3) NULL,
	[estado_envio] [nvarchar](10) NOT NULL,
	[intentos] [int] NOT NULL,
 CONSTRAINT [pk_notificacion] PRIMARY KEY CLUSTERED 
(
	[id_notificacion] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[rol] Fecha de script: 21/11/2026 04:02:24 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[rol](
	[id_rol] [int] IDENTITY(1,1) NOT NULL,
	[nombre] [nvarchar](20) NOT NULL,
 CONSTRAINT [pk_rol] PRIMARY KEY CLUSTERED 
(
	[id_rol] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[sede] Fecha de script: 21/11/2026 04:02:24 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[sede](
	[id_sede] [bigint] IDENTITY(1,1) NOT NULL,
	[nombre] [nvarchar](80) NOT NULL,
	[direccion] [nvarchar](150) NOT NULL,
	[telefono] [nvarchar](20) NULL,
 CONSTRAINT [pk_sede] PRIMARY KEY CLUSTERED 
(
	[id_sede] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[servicio] Fecha de script: 21/11/2026 04:02:24 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[servicio](
	[id_servicio] [bigint] IDENTITY(1,1) NOT NULL,
	[id_categoria] [bigint] NOT NULL,
	[nombre] [nvarchar](80) NOT NULL,
	[descripcion] [nvarchar](200) NULL,
	[precio] [decimal](12, 2) NOT NULL,
	[duracion_min] [int] NOT NULL,
	[activo] [bit] NOT NULL,
 CONSTRAINT [pk_servicio] PRIMARY KEY CLUSTERED 
(
	[id_servicio] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[usuario] Fecha de script: 21/11/2026 04:02:24 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[usuario](
	[id_usuario] [bigint] IDENTITY(1,1) NOT NULL,
	[id_rol] [int] NOT NULL,
	[nombres] [nvarchar](80) NOT NULL,
	[apellidos] [nvarchar](80) NOT NULL,
	[email] [nvarchar](120) NOT NULL,
	[telefono] [nvarchar](20) NOT NULL,
	[password_hash] [nvarchar](100) NOT NULL,
	[activo] [bit] NOT NULL,
	[fecha_registro] [datetime2](3) NOT NULL,
	[ultimo_acceso] [datetime2](3) NULL,
 CONSTRAINT [pk_usuario] PRIMARY KEY CLUSTERED 
(
	[id_usuario] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET IDENTITY_INSERT [dbo].[categoria_servicio] ON 

INSERT [dbo].[categoria_servicio] ([id_categoria], [nombre]) VALUES (2, N'Color')
INSERT [dbo].[categoria_servicio] ([id_categoria], [nombre]) VALUES (1, N'Corte')
INSERT [dbo].[categoria_servicio] ([id_categoria], [nombre]) VALUES (3, N'Peinado')
INSERT [dbo].[categoria_servicio] ([id_categoria], [nombre]) VALUES (4, N'Tratamiento')
SET IDENTITY_INSERT [dbo].[categoria_servicio] OFF
GO
SET IDENTITY_INSERT [dbo].[cita] ON 

INSERT [dbo].[cita] ([id_cita], [id_cliente], [id_estilista], [id_sede], [fecha], [hora_inicio], [hora_fin], [estado], [total], [motivo_cancelacion], [fecha_creacion]) VALUES (1, 2, 6, 1, CAST(N'2026-11-21' AS Date), CAST(N'15:00:00' AS Time), CAST(N'15:40:00' AS Time), N'PENDIENTE', CAST(35.00 AS Decimal(12, 2)), NULL, CAST(N'2026-11-21T13:48:52.4470000' AS DateTime2))
INSERT [dbo].[cita] ([id_cita], [id_cliente], [id_estilista], [id_sede], [fecha], [hora_inicio], [hora_fin], [estado], [total], [motivo_cancelacion], [fecha_creacion]) VALUES (2, 2, 6, 1, CAST(N'2026-11-11' AS Date), CAST(N'10:00:00' AS Time), CAST(N'10:40:00' AS Time), N'ATENDIDA', CAST(35.00 AS Decimal(12, 2)), NULL, CAST(N'2026-11-21T13:48:52.4470000' AS DateTime2))
INSERT [dbo].[cita] ([id_cita], [id_cliente], [id_estilista], [id_sede], [fecha], [hora_inicio], [hora_fin], [estado], [total], [motivo_cancelacion], [fecha_creacion]) VALUES (3, 4, 6, 1, CAST(N'2026-11-15' AS Date), CAST(N'12:00:00' AS Time), CAST(N'12:40:00' AS Time), N'AUSENTE', CAST(35.00 AS Decimal(12, 2)), NULL, CAST(N'2026-11-21T13:48:52.4470000' AS DateTime2))
INSERT [dbo].[cita] ([id_cita], [id_cliente], [id_estilista], [id_sede], [fecha], [hora_inicio], [hora_fin], [estado], [total], [motivo_cancelacion], [fecha_creacion]) VALUES (4, 3, 7, 1, CAST(N'2026-11-21' AS Date), CAST(N'11:00:00' AS Time), CAST(N'12:30:00' AS Time), N'CONFIRMADA', CAST(120.00 AS Decimal(12, 2)), NULL, CAST(N'2026-11-21T13:48:52.4470000' AS DateTime2))
INSERT [dbo].[cita] ([id_cita], [id_cliente], [id_estilista], [id_sede], [fecha], [hora_inicio], [hora_fin], [estado], [total], [motivo_cancelacion], [fecha_creacion]) VALUES (5, 2, 7, 1, CAST(N'2026-11-26' AS Date), CAST(N'11:00:00' AS Time), CAST(N'12:30:00' AS Time), N'PENDIENTE', CAST(120.00 AS Decimal(12, 2)), NULL, CAST(N'2026-11-21T13:48:52.4470000' AS DateTime2))
INSERT [dbo].[cita] ([id_cita], [id_cliente], [id_estilista], [id_sede], [fecha], [hora_inicio], [hora_fin], [estado], [total], [motivo_cancelacion], [fecha_creacion]) VALUES (6, 3, 7, 1, CAST(N'2026-11-09' AS Date), CAST(N'09:00:00' AS Time), CAST(N'10:30:00' AS Time), N'ATENDIDA', CAST(120.00 AS Decimal(12, 2)), NULL, CAST(N'2026-11-21T13:48:52.4470000' AS DateTime2))
INSERT [dbo].[cita] ([id_cita], [id_cliente], [id_estilista], [id_sede], [fecha], [hora_inicio], [hora_fin], [estado], [total], [motivo_cancelacion], [fecha_creacion]) VALUES (7, 5, 8, 1, CAST(N'2026-11-21' AS Date), CAST(N'18:00:00' AS Time), CAST(N'19:00:00' AS Time), N'CANCELADA', CAST(80.00 AS Decimal(12, 2)), NULL, CAST(N'2026-11-21T13:48:52.4470000' AS DateTime2))
INSERT [dbo].[cita] ([id_cita], [id_cliente], [id_estilista], [id_sede], [fecha], [hora_inicio], [hora_fin], [estado], [total], [motivo_cancelacion], [fecha_creacion]) VALUES (8, 2, 8, 1, CAST(N'2026-11-01' AS Date), CAST(N'15:00:00' AS Time), CAST(N'16:00:00' AS Time), N'ATENDIDA', CAST(80.00 AS Decimal(12, 2)), NULL, CAST(N'2026-11-21T13:48:52.4470000' AS DateTime2))
INSERT [dbo].[cita] ([id_cita], [id_cliente], [id_estilista], [id_sede], [fecha], [hora_inicio], [hora_fin], [estado], [total], [motivo_cancelacion], [fecha_creacion]) VALUES (9, 4, 6, 1, CAST(N'2026-11-21' AS Date), CAST(N'16:30:00' AS Time), CAST(N'17:20:00' AS Time), N'CONFIRMADA', CAST(65.00 AS Decimal(12, 2)), NULL, CAST(N'2026-11-21T13:48:52.4470000' AS DateTime2))
INSERT [dbo].[cita] ([id_cita], [id_cliente], [id_estilista], [id_sede], [fecha], [hora_inicio], [hora_fin], [estado], [total], [motivo_cancelacion], [fecha_creacion]) VALUES (10, 2, 6, 1, CAST(N'2026-11-29' AS Date), CAST(N'16:30:00' AS Time), CAST(N'17:20:00' AS Time), N'CONFIRMADA', CAST(65.00 AS Decimal(12, 2)), NULL, CAST(N'2026-11-21T13:48:52.4470000' AS DateTime2))
INSERT [dbo].[cita] ([id_cita], [id_cliente], [id_estilista], [id_sede], [fecha], [hora_inicio], [hora_fin], [estado], [total], [motivo_cancelacion], [fecha_creacion]) VALUES (11, 5, 7, 1, CAST(N'2026-11-18' AS Date), CAST(N'14:00:00' AS Time), CAST(N'14:50:00' AS Time), N'CANCELADA', CAST(65.00 AS Decimal(12, 2)), NULL, CAST(N'2026-11-21T13:48:52.4470000' AS DateTime2))
INSERT [dbo].[cita] ([id_cita], [id_cliente], [id_estilista], [id_sede], [fecha], [hora_inicio], [hora_fin], [estado], [total], [motivo_cancelacion], [fecha_creacion]) VALUES (12, 4, 8, 1, CAST(N'2026-11-21' AS Date), CAST(N'09:30:00' AS Time), CAST(N'10:00:00' AS Time), N'ATENDIDA', CAST(25.00 AS Decimal(12, 2)), NULL, CAST(N'2026-11-21T13:48:52.4470000' AS DateTime2))
INSERT [dbo].[cita] ([id_cita], [id_cliente], [id_estilista], [id_sede], [fecha], [hora_inicio], [hora_fin], [estado], [total], [motivo_cancelacion], [fecha_creacion]) VALUES (13, 2, 8, 1, CAST(N'2026-11-26' AS Date), CAST(N'11:00:00' AS Time), CAST(N'11:40:00' AS Time), N'PENDIENTE', CAST(35.00 AS Decimal(12, 2)), NULL, CAST(N'2026-11-21T15:45:17.8490000' AS DateTime2))
INSERT [dbo].[cita] ([id_cita], [id_cliente], [id_estilista], [id_sede], [fecha], [hora_inicio], [hora_fin], [estado], [total], [motivo_cancelacion], [fecha_creacion]) VALUES (14, 2, 6, 1, CAST(N'2026-12-04' AS Date), CAST(N'18:00:00' AS Time), CAST(N'18:50:00' AS Time), N'PENDIENTE', CAST(65.00 AS Decimal(12, 2)), NULL, CAST(N'2026-11-21T15:48:31.1030000' AS DateTime2))
SET IDENTITY_INSERT [dbo].[cita] OFF
GO
INSERT [dbo].[cliente] ([id_usuario], [acepta_whatsapp], [acepta_correo], [observaciones]) VALUES (2, 1, 1, NULL)
INSERT [dbo].[cliente] ([id_usuario], [acepta_whatsapp], [acepta_correo], [observaciones]) VALUES (3, 1, 1, NULL)
INSERT [dbo].[cliente] ([id_usuario], [acepta_whatsapp], [acepta_correo], [observaciones]) VALUES (4, 1, 1, NULL)
INSERT [dbo].[cliente] ([id_usuario], [acepta_whatsapp], [acepta_correo], [observaciones]) VALUES (5, 1, 1, NULL)
GO
INSERT [dbo].[detalle_cita] ([id_cita], [id_servicio], [precio_aplicado], [duracion_min]) VALUES (1, 1, CAST(35.00 AS Decimal(12, 2)), 40)
INSERT [dbo].[detalle_cita] ([id_cita], [id_servicio], [precio_aplicado], [duracion_min]) VALUES (2, 1, CAST(35.00 AS Decimal(12, 2)), 40)
INSERT [dbo].[detalle_cita] ([id_cita], [id_servicio], [precio_aplicado], [duracion_min]) VALUES (3, 1, CAST(35.00 AS Decimal(12, 2)), 40)
INSERT [dbo].[detalle_cita] ([id_cita], [id_servicio], [precio_aplicado], [duracion_min]) VALUES (4, 2, CAST(120.00 AS Decimal(12, 2)), 90)
INSERT [dbo].[detalle_cita] ([id_cita], [id_servicio], [precio_aplicado], [duracion_min]) VALUES (5, 2, CAST(120.00 AS Decimal(12, 2)), 90)
INSERT [dbo].[detalle_cita] ([id_cita], [id_servicio], [precio_aplicado], [duracion_min]) VALUES (6, 2, CAST(120.00 AS Decimal(12, 2)), 90)
INSERT [dbo].[detalle_cita] ([id_cita], [id_servicio], [precio_aplicado], [duracion_min]) VALUES (7, 3, CAST(80.00 AS Decimal(12, 2)), 60)
INSERT [dbo].[detalle_cita] ([id_cita], [id_servicio], [precio_aplicado], [duracion_min]) VALUES (8, 3, CAST(80.00 AS Decimal(12, 2)), 60)
INSERT [dbo].[detalle_cita] ([id_cita], [id_servicio], [precio_aplicado], [duracion_min]) VALUES (9, 4, CAST(65.00 AS Decimal(12, 2)), 50)
INSERT [dbo].[detalle_cita] ([id_cita], [id_servicio], [precio_aplicado], [duracion_min]) VALUES (10, 4, CAST(65.00 AS Decimal(12, 2)), 50)
INSERT [dbo].[detalle_cita] ([id_cita], [id_servicio], [precio_aplicado], [duracion_min]) VALUES (11, 4, CAST(65.00 AS Decimal(12, 2)), 50)
INSERT [dbo].[detalle_cita] ([id_cita], [id_servicio], [precio_aplicado], [duracion_min]) VALUES (12, 6, CAST(25.00 AS Decimal(12, 2)), 30)
INSERT [dbo].[detalle_cita] ([id_cita], [id_servicio], [precio_aplicado], [duracion_min]) VALUES (13, 1, CAST(35.00 AS Decimal(12, 2)), 40)
INSERT [dbo].[detalle_cita] ([id_cita], [id_servicio], [precio_aplicado], [duracion_min]) VALUES (14, 4, CAST(65.00 AS Decimal(12, 2)), 50)
GO
INSERT [dbo].[estilista] ([id_usuario], [id_sede], [especialidad]) VALUES (6, 1, N'Corte')
INSERT [dbo].[estilista] ([id_usuario], [id_sede], [especialidad]) VALUES (7, 1, N'Color y tratamientos')
INSERT [dbo].[estilista] ([id_usuario], [id_sede], [especialidad]) VALUES (8, 1, N'Peinados de evento')
GO
INSERT [dbo].[estilista_servicio] ([id_estilista], [id_servicio]) VALUES (6, 1)
INSERT [dbo].[estilista_servicio] ([id_estilista], [id_servicio]) VALUES (6, 4)
INSERT [dbo].[estilista_servicio] ([id_estilista], [id_servicio]) VALUES (6, 6)
INSERT [dbo].[estilista_servicio] ([id_estilista], [id_servicio]) VALUES (7, 2)
INSERT [dbo].[estilista_servicio] ([id_estilista], [id_servicio]) VALUES (7, 4)
INSERT [dbo].[estilista_servicio] ([id_estilista], [id_servicio]) VALUES (7, 5)
INSERT [dbo].[estilista_servicio] ([id_estilista], [id_servicio]) VALUES (7, 6)
INSERT [dbo].[estilista_servicio] ([id_estilista], [id_servicio]) VALUES (8, 1)
INSERT [dbo].[estilista_servicio] ([id_estilista], [id_servicio]) VALUES (8, 3)
INSERT [dbo].[estilista_servicio] ([id_estilista], [id_servicio]) VALUES (8, 6)
GO
SET IDENTITY_INSERT [dbo].[horario_estilista] ON 

INSERT [dbo].[horario_estilista] ([id_horario], [id_estilista], [dia_semana], [hora_inicio], [hora_fin]) VALUES (1, 8, 1, CAST(N'09:00:00' AS Time), CAST(N'19:00:00' AS Time))
INSERT [dbo].[horario_estilista] ([id_horario], [id_estilista], [dia_semana], [hora_inicio], [hora_fin]) VALUES (2, 8, 2, CAST(N'09:00:00' AS Time), CAST(N'19:00:00' AS Time))
INSERT [dbo].[horario_estilista] ([id_horario], [id_estilista], [dia_semana], [hora_inicio], [hora_fin]) VALUES (3, 8, 3, CAST(N'09:00:00' AS Time), CAST(N'19:00:00' AS Time))
INSERT [dbo].[horario_estilista] ([id_horario], [id_estilista], [dia_semana], [hora_inicio], [hora_fin]) VALUES (4, 8, 4, CAST(N'09:00:00' AS Time), CAST(N'19:00:00' AS Time))
INSERT [dbo].[horario_estilista] ([id_horario], [id_estilista], [dia_semana], [hora_inicio], [hora_fin]) VALUES (5, 8, 5, CAST(N'09:00:00' AS Time), CAST(N'19:00:00' AS Time))
INSERT [dbo].[horario_estilista] ([id_horario], [id_estilista], [dia_semana], [hora_inicio], [hora_fin]) VALUES (6, 8, 6, CAST(N'09:00:00' AS Time), CAST(N'17:00:00' AS Time))
INSERT [dbo].[horario_estilista] ([id_horario], [id_estilista], [dia_semana], [hora_inicio], [hora_fin]) VALUES (7, 6, 1, CAST(N'09:00:00' AS Time), CAST(N'19:00:00' AS Time))
INSERT [dbo].[horario_estilista] ([id_horario], [id_estilista], [dia_semana], [hora_inicio], [hora_fin]) VALUES (8, 6, 2, CAST(N'09:00:00' AS Time), CAST(N'19:00:00' AS Time))
INSERT [dbo].[horario_estilista] ([id_horario], [id_estilista], [dia_semana], [hora_inicio], [hora_fin]) VALUES (9, 6, 3, CAST(N'09:00:00' AS Time), CAST(N'19:00:00' AS Time))
INSERT [dbo].[horario_estilista] ([id_horario], [id_estilista], [dia_semana], [hora_inicio], [hora_fin]) VALUES (10, 6, 4, CAST(N'09:00:00' AS Time), CAST(N'19:00:00' AS Time))
INSERT [dbo].[horario_estilista] ([id_horario], [id_estilista], [dia_semana], [hora_inicio], [hora_fin]) VALUES (11, 6, 5, CAST(N'09:00:00' AS Time), CAST(N'19:00:00' AS Time))
INSERT [dbo].[horario_estilista] ([id_horario], [id_estilista], [dia_semana], [hora_inicio], [hora_fin]) VALUES (12, 6, 6, CAST(N'09:00:00' AS Time), CAST(N'17:00:00' AS Time))
INSERT [dbo].[horario_estilista] ([id_horario], [id_estilista], [dia_semana], [hora_inicio], [hora_fin]) VALUES (13, 7, 1, CAST(N'09:00:00' AS Time), CAST(N'19:00:00' AS Time))
INSERT [dbo].[horario_estilista] ([id_horario], [id_estilista], [dia_semana], [hora_inicio], [hora_fin]) VALUES (14, 7, 2, CAST(N'09:00:00' AS Time), CAST(N'19:00:00' AS Time))
INSERT [dbo].[horario_estilista] ([id_horario], [id_estilista], [dia_semana], [hora_inicio], [hora_fin]) VALUES (15, 7, 3, CAST(N'09:00:00' AS Time), CAST(N'19:00:00' AS Time))
INSERT [dbo].[horario_estilista] ([id_horario], [id_estilista], [dia_semana], [hora_inicio], [hora_fin]) VALUES (16, 7, 4, CAST(N'09:00:00' AS Time), CAST(N'19:00:00' AS Time))
INSERT [dbo].[horario_estilista] ([id_horario], [id_estilista], [dia_semana], [hora_inicio], [hora_fin]) VALUES (17, 7, 5, CAST(N'09:00:00' AS Time), CAST(N'19:00:00' AS Time))
INSERT [dbo].[horario_estilista] ([id_horario], [id_estilista], [dia_semana], [hora_inicio], [hora_fin]) VALUES (18, 7, 6, CAST(N'09:00:00' AS Time), CAST(N'17:00:00' AS Time))
SET IDENTITY_INSERT [dbo].[horario_estilista] OFF
GO
SET IDENTITY_INSERT [dbo].[notificacion] ON 

INSERT [dbo].[notificacion] ([id_notificacion], [id_cita], [tipo], [canal], [mensaje], [fecha_programada], [fecha_envio], [estado_envio], [intentos]) VALUES (1, 13, N'REGISTRO', N'WHATSAPP', N'Tu cita del 26/11/2026 11:00 fue registrada y esta pendiente de confirmacion.', CAST(N'2026-11-21T15:45:17.8600000' AS DateTime2), CAST(N'2026-11-21T15:45:37.5160000' AS DateTime2), N'ENVIADA', 0)
INSERT [dbo].[notificacion] ([id_notificacion], [id_cita], [tipo], [canal], [mensaje], [fecha_programada], [fecha_envio], [estado_envio], [intentos]) VALUES (2, 13, N'REGISTRO', N'CORREO', N'Tu cita del 26/11/2026 11:00 fue registrada y esta pendiente de confirmacion.', CAST(N'2026-11-21T15:45:17.8600000' AS DateTime2), CAST(N'2026-11-21T15:45:37.5160000' AS DateTime2), N'ENVIADA', 0)
INSERT [dbo].[notificacion] ([id_notificacion], [id_cita], [tipo], [canal], [mensaje], [fecha_programada], [fecha_envio], [estado_envio], [intentos]) VALUES (3, 14, N'REGISTRO', N'WHATSAPP', N'Tu cita del 04/12/2026 18:00 fue registrada y esta pendiente de confirmacion.', CAST(N'2026-11-21T15:48:31.1040000' AS DateTime2), CAST(N'2026-11-21T15:48:37.5450000' AS DateTime2), N'ENVIADA', 0)
INSERT [dbo].[notificacion] ([id_notificacion], [id_cita], [tipo], [canal], [mensaje], [fecha_programada], [fecha_envio], [estado_envio], [intentos]) VALUES (4, 14, N'REGISTRO', N'CORREO', N'Tu cita del 04/12/2026 18:00 fue registrada y esta pendiente de confirmacion.', CAST(N'2026-11-21T15:48:31.1040000' AS DateTime2), CAST(N'2026-11-21T15:48:37.5460000' AS DateTime2), N'ENVIADA', 0)
SET IDENTITY_INSERT [dbo].[notificacion] OFF
GO
SET IDENTITY_INSERT [dbo].[rol] ON 

INSERT [dbo].[rol] ([id_rol], [nombre]) VALUES (3, N'ADMINISTRADOR')
INSERT [dbo].[rol] ([id_rol], [nombre]) VALUES (1, N'CLIENTE')
INSERT [dbo].[rol] ([id_rol], [nombre]) VALUES (2, N'ESTILISTA')
SET IDENTITY_INSERT [dbo].[rol] OFF
GO
SET IDENTITY_INSERT [dbo].[sede] ON 

INSERT [dbo].[sede] ([id_sede], [nombre], [direccion], [telefono]) VALUES (1, N'Bella Estilo - Sede principal', N'Dirección de demostración', NULL)
SET IDENTITY_INSERT [dbo].[sede] OFF
GO
SET IDENTITY_INSERT [dbo].[servicio] ON 

INSERT [dbo].[servicio] ([id_servicio], [id_categoria], [nombre], [descripcion], [precio], [duracion_min], [activo]) VALUES (1, 1, N'Corte de cabello', N'Corte con estilista a elección', CAST(35.00 AS Decimal(12, 2)), 40, 1)
INSERT [dbo].[servicio] ([id_servicio], [id_categoria], [nombre], [descripcion], [precio], [duracion_min], [activo]) VALUES (2, 2, N'Tinte y color', N'Incluye lavado', CAST(120.00 AS Decimal(12, 2)), 90, 1)
INSERT [dbo].[servicio] ([id_servicio], [id_categoria], [nombre], [descripcion], [precio], [duracion_min], [activo]) VALUES (3, 3, N'Peinado para evento', N'Reservar con 24 h de anticipación', CAST(80.00 AS Decimal(12, 2)), 60, 1)
INSERT [dbo].[servicio] ([id_servicio], [id_categoria], [nombre], [descripcion], [precio], [duracion_min], [activo]) VALUES (4, 4, N'Tratamiento capilar', N'Hidratación profunda', CAST(65.00 AS Decimal(12, 2)), 50, 1)
INSERT [dbo].[servicio] ([id_servicio], [id_categoria], [nombre], [descripcion], [precio], [duracion_min], [activo]) VALUES (5, 4, N'Alisado permanente', N'Consultar disponibilidad', CAST(180.00 AS Decimal(12, 2)), 120, 0)
INSERT [dbo].[servicio] ([id_servicio], [id_categoria], [nombre], [descripcion], [precio], [duracion_min], [activo]) VALUES (6, 3, N'Lavado y secado', N'Incluye masaje capilar', CAST(25.00 AS Decimal(12, 2)), 30, 1)
SET IDENTITY_INSERT [dbo].[servicio] OFF
GO
SET IDENTITY_INSERT [dbo].[usuario] ON 

INSERT [dbo].[usuario] ([id_usuario], [id_rol], [nombres], [apellidos], [email], [telefono], [password_hash], [activo], [fecha_registro], [ultimo_acceso]) VALUES (1, 3, N'Recepción', N'Bella Estilo', N'recepcion@bellaestilo.pe', N'987000111', N'$2b$10$.PN3quV7DmYHHE2XqOu73u8VQghswxOYXZ1t77144EwUWJesr5dX.', 1, CAST(N'2026-11-21T13:48:52.3880000' AS DateTime2), NULL)
INSERT [dbo].[usuario] ([id_usuario], [id_rol], [nombres], [apellidos], [email], [telefono], [password_hash], [activo], [fecha_registro], [ultimo_acceso]) VALUES (2, 1, N'Valeria', N'Rojas Díaz', N'valeria.rojas@correo.com', N'987654321', N'$2b$10$C5DlU5jvrD0AMPVYoNQVQuAm39HzaoFgZnHlGwAPfxszMPxy0bmYG', 1, CAST(N'2026-11-21T13:48:52.3880000' AS DateTime2), CAST(N'2026-11-21T15:45:07.0680000' AS DateTime2))
INSERT [dbo].[usuario] ([id_usuario], [id_rol], [nombres], [apellidos], [email], [telefono], [password_hash], [activo], [fecha_registro], [ultimo_acceso]) VALUES (3, 1, N'Jimena', N'Torres', N'jimena.torres@correo.com', N'991223344', N'$2b$10$C5DlU5jvrD0AMPVYoNQVQuAm39HzaoFgZnHlGwAPfxszMPxy0bmYG', 1, CAST(N'2026-11-21T13:48:52.3880000' AS DateTime2), NULL)
INSERT [dbo].[usuario] ([id_usuario], [id_rol], [nombres], [apellidos], [email], [telefono], [password_hash], [activo], [fecha_registro], [ultimo_acceso]) VALUES (4, 1, N'Rosa', N'Sánchez', N'rosa.sanchez@correo.com', N'977112233', N'$2b$10$C5DlU5jvrD0AMPVYoNQVQuAm39HzaoFgZnHlGwAPfxszMPxy0bmYG', 1, CAST(N'2026-11-21T13:48:52.3880000' AS DateTime2), NULL)
INSERT [dbo].[usuario] ([id_usuario], [id_rol], [nombres], [apellidos], [email], [telefono], [password_hash], [activo], [fecha_registro], [ultimo_acceso]) VALUES (5, 1, N'Carla', N'Medina', N'carla.medina@correo.com', N'966554433', N'$2b$10$C5DlU5jvrD0AMPVYoNQVQuAm39HzaoFgZnHlGwAPfxszMPxy0bmYG', 1, CAST(N'2026-11-21T13:48:52.3880000' AS DateTime2), NULL)
INSERT [dbo].[usuario] ([id_usuario], [id_rol], [nombres], [apellidos], [email], [telefono], [password_hash], [activo], [fecha_registro], [ultimo_acceso]) VALUES (6, 2, N'Milagros', N'Ramos', N'milagros@bellaestilo.pe', N'987000222', N'$2b$10$dnsMcBcbmFEfhPUiRSqNnOMt6W8RBviHfjhSDYd7cABjJdwIjEviK', 1, CAST(N'2026-11-21T13:48:52.3880000' AS DateTime2), NULL)
INSERT [dbo].[usuario] ([id_usuario], [id_rol], [nombres], [apellidos], [email], [telefono], [password_hash], [activo], [fecha_registro], [ultimo_acceso]) VALUES (7, 2, N'Rosa', N'Salinas', N'rosa@bellaestilo.pe', N'987000222', N'$2b$10$dnsMcBcbmFEfhPUiRSqNnOMt6W8RBviHfjhSDYd7cABjJdwIjEviK', 1, CAST(N'2026-11-21T13:48:52.3880000' AS DateTime2), NULL)
INSERT [dbo].[usuario] ([id_usuario], [id_rol], [nombres], [apellidos], [email], [telefono], [password_hash], [activo], [fecha_registro], [ultimo_acceso]) VALUES (8, 2, N'Jimena', N'Tello', N'jimena@bellaestilo.pe', N'987000222', N'$2b$10$dnsMcBcbmFEfhPUiRSqNnOMt6W8RBviHfjhSDYd7cABjJdwIjEviK', 1, CAST(N'2026-11-21T13:48:52.3880000' AS DateTime2), NULL)
SET IDENTITY_INSERT [dbo].[usuario] OFF
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_categoria_nombre] Fecha de script: 21/11/2026 04:02:24 p. m. ******/
ALTER TABLE [dbo].[categoria_servicio] ADD  CONSTRAINT [uq_categoria_nombre] UNIQUE NONCLUSTERED 
(
	[nombre] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Objeto: Index [ix_cita_cliente_fecha] Fecha de script: 21/11/2026 04:02:24 p. m. ******/
CREATE NONCLUSTERED INDEX [ix_cita_cliente_fecha] ON [dbo].[cita]
(
	[id_cliente] ASC,
	[fecha] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [ix_cita_fecha_estado] Fecha de script: 21/11/2026 04:02:24 p. m. ******/
CREATE NONCLUSTERED INDEX [ix_cita_fecha_estado] ON [dbo].[cita]
(
	[fecha] ASC,
	[estado] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Objeto: Index [ux_cita_slot_activo] Fecha de script: 21/11/2026 04:02:24 p. m. ******/
CREATE UNIQUE NONCLUSTERED INDEX [ux_cita_slot_activo] ON [dbo].[cita]
(
	[id_estilista] ASC,
	[fecha] ASC,
	[hora_inicio] ASC
)
WHERE ([estado]<>N'CANCELADA')
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Objeto: Index [uq_horario] Fecha de script: 21/11/2026 04:02:24 p. m. ******/
ALTER TABLE [dbo].[horario_estilista] ADD  CONSTRAINT [uq_horario] UNIQUE NONCLUSTERED 
(
	[id_estilista] ASC,
	[dia_semana] ASC,
	[hora_inicio] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [ix_notif_pendientes] Fecha de script: 21/11/2026 04:02:24 p. m. ******/
CREATE NONCLUSTERED INDEX [ix_notif_pendientes] ON [dbo].[notificacion]
(
	[estado_envio] ASC,
	[fecha_programada] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_rol_nombre] Fecha de script: 21/11/2026 04:02:24 p. m. ******/
ALTER TABLE [dbo].[rol] ADD  CONSTRAINT [uq_rol_nombre] UNIQUE NONCLUSTERED 
(
	[nombre] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_usuario_email] Fecha de script: 21/11/2026 04:02:24 p. m. ******/
ALTER TABLE [dbo].[usuario] ADD  CONSTRAINT [uq_usuario_email] UNIQUE NONCLUSTERED 
(
	[email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[auditoria] ADD  CONSTRAINT [df_auditoria_fecha]  DEFAULT (sysdatetime()) FOR [fecha]
GO
ALTER TABLE [dbo].[cita] ADD  CONSTRAINT [df_cita_estado]  DEFAULT (N'PENDIENTE') FOR [estado]
GO
ALTER TABLE [dbo].[cita] ADD  CONSTRAINT [df_cita_creacion]  DEFAULT (sysdatetime()) FOR [fecha_creacion]
GO
ALTER TABLE [dbo].[cliente] ADD  CONSTRAINT [df_cliente_whatsapp]  DEFAULT ((1)) FOR [acepta_whatsapp]
GO
ALTER TABLE [dbo].[cliente] ADD  CONSTRAINT [df_cliente_correo]  DEFAULT ((1)) FOR [acepta_correo]
GO
ALTER TABLE [dbo].[notificacion] ADD  CONSTRAINT [df_notificacion_estado]  DEFAULT (N'PENDIENTE') FOR [estado_envio]
GO
ALTER TABLE [dbo].[notificacion] ADD  CONSTRAINT [df_notificacion_intentos]  DEFAULT ((0)) FOR [intentos]
GO
ALTER TABLE [dbo].[servicio] ADD  CONSTRAINT [df_servicio_activo]  DEFAULT ((1)) FOR [activo]
GO
ALTER TABLE [dbo].[usuario] ADD  CONSTRAINT [df_usuario_activo]  DEFAULT ((1)) FOR [activo]
GO
ALTER TABLE [dbo].[usuario] ADD  CONSTRAINT [df_usuario_registro]  DEFAULT (sysdatetime()) FOR [fecha_registro]
GO
ALTER TABLE [dbo].[auditoria]  WITH CHECK ADD  CONSTRAINT [fk_audit_usuario] FOREIGN KEY([id_usuario])
REFERENCES [dbo].[usuario] ([id_usuario])
GO
ALTER TABLE [dbo].[auditoria] CHECK CONSTRAINT [fk_audit_usuario]
GO
ALTER TABLE [dbo].[cita]  WITH CHECK ADD  CONSTRAINT [fk_cita_cliente] FOREIGN KEY([id_cliente])
REFERENCES [dbo].[cliente] ([id_usuario])
GO
ALTER TABLE [dbo].[cita] CHECK CONSTRAINT [fk_cita_cliente]
GO
ALTER TABLE [dbo].[cita]  WITH CHECK ADD  CONSTRAINT [fk_cita_estilista] FOREIGN KEY([id_estilista])
REFERENCES [dbo].[estilista] ([id_usuario])
GO
ALTER TABLE [dbo].[cita] CHECK CONSTRAINT [fk_cita_estilista]
GO
ALTER TABLE [dbo].[cita]  WITH CHECK ADD  CONSTRAINT [fk_cita_sede] FOREIGN KEY([id_sede])
REFERENCES [dbo].[sede] ([id_sede])
GO
ALTER TABLE [dbo].[cita] CHECK CONSTRAINT [fk_cita_sede]
GO
ALTER TABLE [dbo].[cliente]  WITH CHECK ADD  CONSTRAINT [fk_cliente_usuario] FOREIGN KEY([id_usuario])
REFERENCES [dbo].[usuario] ([id_usuario])
GO
ALTER TABLE [dbo].[cliente] CHECK CONSTRAINT [fk_cliente_usuario]
GO
ALTER TABLE [dbo].[detalle_cita]  WITH CHECK ADD  CONSTRAINT [fk_detalle_cita] FOREIGN KEY([id_cita])
REFERENCES [dbo].[cita] ([id_cita])
GO
ALTER TABLE [dbo].[detalle_cita] CHECK CONSTRAINT [fk_detalle_cita]
GO
ALTER TABLE [dbo].[detalle_cita]  WITH CHECK ADD  CONSTRAINT [fk_detalle_servicio] FOREIGN KEY([id_servicio])
REFERENCES [dbo].[servicio] ([id_servicio])
GO
ALTER TABLE [dbo].[detalle_cita] CHECK CONSTRAINT [fk_detalle_servicio]
GO
ALTER TABLE [dbo].[estilista]  WITH CHECK ADD  CONSTRAINT [fk_estilista_sede] FOREIGN KEY([id_sede])
REFERENCES [dbo].[sede] ([id_sede])
GO
ALTER TABLE [dbo].[estilista] CHECK CONSTRAINT [fk_estilista_sede]
GO
ALTER TABLE [dbo].[estilista]  WITH CHECK ADD  CONSTRAINT [fk_estilista_usuario] FOREIGN KEY([id_usuario])
REFERENCES [dbo].[usuario] ([id_usuario])
GO
ALTER TABLE [dbo].[estilista] CHECK CONSTRAINT [fk_estilista_usuario]
GO
ALTER TABLE [dbo].[estilista_servicio]  WITH CHECK ADD  CONSTRAINT [fk_es_estilista] FOREIGN KEY([id_estilista])
REFERENCES [dbo].[estilista] ([id_usuario])
GO
ALTER TABLE [dbo].[estilista_servicio] CHECK CONSTRAINT [fk_es_estilista]
GO
ALTER TABLE [dbo].[estilista_servicio]  WITH CHECK ADD  CONSTRAINT [fk_es_servicio] FOREIGN KEY([id_servicio])
REFERENCES [dbo].[servicio] ([id_servicio])
GO
ALTER TABLE [dbo].[estilista_servicio] CHECK CONSTRAINT [fk_es_servicio]
GO
ALTER TABLE [dbo].[horario_estilista]  WITH CHECK ADD  CONSTRAINT [fk_horario_estilista] FOREIGN KEY([id_estilista])
REFERENCES [dbo].[estilista] ([id_usuario])
GO
ALTER TABLE [dbo].[horario_estilista] CHECK CONSTRAINT [fk_horario_estilista]
GO
ALTER TABLE [dbo].[notificacion]  WITH CHECK ADD  CONSTRAINT [fk_notif_cita] FOREIGN KEY([id_cita])
REFERENCES [dbo].[cita] ([id_cita])
GO
ALTER TABLE [dbo].[notificacion] CHECK CONSTRAINT [fk_notif_cita]
GO
ALTER TABLE [dbo].[servicio]  WITH CHECK ADD  CONSTRAINT [fk_servicio_categoria] FOREIGN KEY([id_categoria])
REFERENCES [dbo].[categoria_servicio] ([id_categoria])
GO
ALTER TABLE [dbo].[servicio] CHECK CONSTRAINT [fk_servicio_categoria]
GO
ALTER TABLE [dbo].[usuario]  WITH CHECK ADD  CONSTRAINT [fk_usuario_rol] FOREIGN KEY([id_rol])
REFERENCES [dbo].[rol] ([id_rol])
GO
ALTER TABLE [dbo].[usuario] CHECK CONSTRAINT [fk_usuario_rol]
GO
ALTER TABLE [dbo].[cita]  WITH CHECK ADD  CONSTRAINT [ck_cita_estado] CHECK  (([estado]=N'AUSENTE' OR [estado]=N'ATENDIDA' OR [estado]=N'CANCELADA' OR [estado]=N'CONFIRMADA' OR [estado]=N'PENDIENTE'))
GO
ALTER TABLE [dbo].[cita] CHECK CONSTRAINT [ck_cita_estado]
GO
ALTER TABLE [dbo].[cita]  WITH CHECK ADD  CONSTRAINT [ck_cita_horas] CHECK  (([hora_fin]>[hora_inicio]))
GO
ALTER TABLE [dbo].[cita] CHECK CONSTRAINT [ck_cita_horas]
GO
ALTER TABLE [dbo].[cita]  WITH CHECK ADD  CONSTRAINT [ck_cita_total] CHECK  (([total]>=(0)))
GO
ALTER TABLE [dbo].[cita] CHECK CONSTRAINT [ck_cita_total]
GO
ALTER TABLE [dbo].[horario_estilista]  WITH CHECK ADD  CONSTRAINT [ck_horario_dia] CHECK  (([dia_semana]>=(1) AND [dia_semana]<=(7)))
GO
ALTER TABLE [dbo].[horario_estilista] CHECK CONSTRAINT [ck_horario_dia]
GO
ALTER TABLE [dbo].[horario_estilista]  WITH CHECK ADD  CONSTRAINT [ck_horario_horas] CHECK  (([hora_fin]>[hora_inicio]))
GO
ALTER TABLE [dbo].[horario_estilista] CHECK CONSTRAINT [ck_horario_horas]
GO
ALTER TABLE [dbo].[notificacion]  WITH CHECK ADD  CONSTRAINT [ck_notificacion_canal] CHECK  (([canal]=N'CORREO' OR [canal]=N'WHATSAPP'))
GO
ALTER TABLE [dbo].[notificacion] CHECK CONSTRAINT [ck_notificacion_canal]
GO
ALTER TABLE [dbo].[notificacion]  WITH CHECK ADD  CONSTRAINT [ck_notificacion_estado] CHECK  (([estado_envio]=N'FALLIDA' OR [estado_envio]=N'ENVIADA' OR [estado_envio]=N'PENDIENTE'))
GO
ALTER TABLE [dbo].[notificacion] CHECK CONSTRAINT [ck_notificacion_estado]
GO
ALTER TABLE [dbo].[notificacion]  WITH CHECK ADD  CONSTRAINT [ck_notificacion_tipo] CHECK  (([tipo]=N'REPROGRAMACION' OR [tipo]=N'CANCELACION' OR [tipo]=N'RECORDATORIO' OR [tipo]=N'CONFIRMACION' OR [tipo]=N'REGISTRO'))
GO
ALTER TABLE [dbo].[notificacion] CHECK CONSTRAINT [ck_notificacion_tipo]
GO
ALTER TABLE [dbo].[servicio]  WITH CHECK ADD  CONSTRAINT [ck_servicio_duracion] CHECK  (([duracion_min]>(0)))
GO
ALTER TABLE [dbo].[servicio] CHECK CONSTRAINT [ck_servicio_duracion]
GO
ALTER TABLE [dbo].[servicio]  WITH CHECK ADD  CONSTRAINT [ck_servicio_precio] CHECK  (([precio]>=(0)))
GO
ALTER TABLE [dbo].[servicio] CHECK CONSTRAINT [ck_servicio_precio]
GO
