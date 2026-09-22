IF OBJECT_ID(N'[__EFMigrationsHistory]') IS NULL
BEGIN
    CREATE TABLE [__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
END;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260922173855_InitialCreate'
)
BEGIN
    CREATE TABLE [Recursos] (
        [Id] int NOT NULL IDENTITY,
        [Codigo] nvarchar(50) NOT NULL,
        [Nombre] nvarchar(150) NOT NULL,
        [Tipo] int NOT NULL,
        [Ubicacion] nvarchar(150) NOT NULL,
        [Descripcion] nvarchar(500) NULL,
        [Estado] int NOT NULL,
        [FechaRegistro] datetime2 NOT NULL,
        CONSTRAINT [PK_Recursos] PRIMARY KEY ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260922173855_InitialCreate'
)
BEGIN
    CREATE TABLE [Usuarios] (
        [Id] int NOT NULL IDENTITY,
        [NombreCompleto] nvarchar(150) NOT NULL,
        [Correo] nvarchar(100) NOT NULL,
        [PasswordHash] nvarchar(255) NOT NULL,
        [Rol] int NOT NULL,
        [Telefono] nvarchar(20) NULL,
        [CarreraODepartamento] nvarchar(150) NULL,
        [FechaRegistro] datetime2 NOT NULL,
        [Activo] bit NOT NULL,
        CONSTRAINT [PK_Usuarios] PRIMARY KEY ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260922173855_InitialCreate'
)
BEGIN
    CREATE TABLE [Solicitudes] (
        [Id] int NOT NULL IDENTITY,
        [CodigoTicket] nvarchar(20) NOT NULL,
        [Titulo] nvarchar(200) NOT NULL,
        [Descripcion] nvarchar(max) NOT NULL,
        [Categoria] int NOT NULL,
        [Prioridad] int NOT NULL,
        [Estado] int NOT NULL,
        [FechaCreacion] datetime2 NOT NULL,
        [FechaActualizacion] datetime2 NULL,
        [FechaCierre] datetime2 NULL,
        [SolicitanteId] int NOT NULL,
        [AsignadoAId] int NULL,
        [RecursoId] int NULL,
        CONSTRAINT [PK_Solicitudes] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Solicitudes_Recursos_RecursoId] FOREIGN KEY ([RecursoId]) REFERENCES [Recursos] ([Id]) ON DELETE SET NULL,
        CONSTRAINT [FK_Solicitudes_Usuarios_AsignadoAId] FOREIGN KEY ([AsignadoAId]) REFERENCES [Usuarios] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_Solicitudes_Usuarios_SolicitanteId] FOREIGN KEY ([SolicitanteId]) REFERENCES [Usuarios] ([Id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260922173855_InitialCreate'
)
BEGIN
    CREATE TABLE [Comentarios] (
        [Id] int NOT NULL IDENTITY,
        [Mensaje] nvarchar(max) NOT NULL,
        [FechaCreacion] datetime2 NOT NULL,
        [EsInterno] bit NOT NULL,
        [SolicitudId] int NOT NULL,
        [UsuarioId] int NOT NULL,
        CONSTRAINT [PK_Comentarios] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Comentarios_Solicitudes_SolicitudId] FOREIGN KEY ([SolicitudId]) REFERENCES [Solicitudes] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_Comentarios_Usuarios_UsuarioId] FOREIGN KEY ([UsuarioId]) REFERENCES [Usuarios] ([Id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260922173855_InitialCreate'
)
BEGIN
    CREATE TABLE [Evidencias] (
        [Id] int NOT NULL IDENTITY,
        [NombreArchivoOriginal] nvarchar(255) NOT NULL,
        [NombreAlmacenado] nvarchar(255) NOT NULL,
        [RutaRelativa] nvarchar(500) NOT NULL,
        [ContentType] nvarchar(100) NOT NULL,
        [TamanoBytes] bigint NOT NULL,
        [FechaSubida] datetime2 NOT NULL,
        [SolicitudId] int NOT NULL,
        [SubidoPorId] int NOT NULL,
        CONSTRAINT [PK_Evidencias] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Evidencias_Solicitudes_SolicitudId] FOREIGN KEY ([SolicitudId]) REFERENCES [Solicitudes] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_Evidencias_Usuarios_SubidoPorId] FOREIGN KEY ([SubidoPorId]) REFERENCES [Usuarios] ([Id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260922173855_InitialCreate'
)
BEGIN
    IF EXISTS (SELECT * FROM [sys].[identity_columns] WHERE [name] IN (N'Id', N'Codigo', N'Descripcion', N'Estado', N'FechaRegistro', N'Nombre', N'Tipo', N'Ubicacion') AND [object_id] = OBJECT_ID(N'[Recursos]'))
        SET IDENTITY_INSERT [Recursos] ON;
    EXEC(N'INSERT INTO [Recursos] ([Id], [Codigo], [Descripcion], [Estado], [FechaRegistro], [Nombre], [Tipo], [Ubicacion])
    VALUES (1, N''LAB-SIS-05'', N''PC de desarrollo para asignaturas de desarrollo y bases de datos'', 1, ''2026-01-15T08:00:00.0000000Z'', N''Equipo de Cómputo Dell Core i7'', 2, N''Edificio A - Laboratorio de Sistemas 1''),
    (2, N''AUD-PROY-01'', N''Sistema de proyección para conferencias y ponencias'', 1, ''2026-01-15T08:00:00.0000000Z'', N''Proyector Láser Epson 4K'', 2, N''Edificio Central - Auditorio Mayor''),
    (3, N''AULA-204-CLIMA'', N''Climatización de 24,000 BTU'', 1, ''2026-01-15T08:00:00.0000000Z'', N''Unidad Central de Aire Acondicionado'', 1, N''Edificio B - Aula Magna 204'')');
    IF EXISTS (SELECT * FROM [sys].[identity_columns] WHERE [name] IN (N'Id', N'Codigo', N'Descripcion', N'Estado', N'FechaRegistro', N'Nombre', N'Tipo', N'Ubicacion') AND [object_id] = OBJECT_ID(N'[Recursos]'))
        SET IDENTITY_INSERT [Recursos] OFF;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260922173855_InitialCreate'
)
BEGIN
    IF EXISTS (SELECT * FROM [sys].[identity_columns] WHERE [name] IN (N'Id', N'Activo', N'CarreraODepartamento', N'Correo', N'FechaRegistro', N'NombreCompleto', N'PasswordHash', N'Rol', N'Telefono') AND [object_id] = OBJECT_ID(N'[Usuarios]'))
        SET IDENTITY_INSERT [Usuarios] ON;
    EXEC(N'INSERT INTO [Usuarios] ([Id], [Activo], [CarreraODepartamento], [Correo], [FechaRegistro], [NombreCompleto], [PasswordHash], [Rol], [Telefono])
    VALUES (1, CAST(1 AS bit), N''Ingeniería de Sistemas'', N''juan.perez@universidad.edu'', ''2026-01-15T08:00:00.0000000Z'', N''Juan Pérez (Estudiante)'', N''hashed_secret_password_123'', 1, N''555-0101''),
    (2, CAST(1 AS bit), N''Dirección de Infraestructura y Servicios'', N''maria.gomez@universidad.edu'', ''2026-01-15T08:00:00.0000000Z'', N''Dra. María Gómez (Administradora)'', N''hashed_secret_admin_123'', 2, N''555-0202''),
    (3, CAST(1 AS bit), N''Centro de Tecnologías de Información'', N''carlos.rivas@universidad.edu'', ''2026-01-15T08:00:00.0000000Z'', N''Ing. Carlos Rivas (Soporte TI)'', N''hashed_secret_tech_123'', 3, N''555-0303'')');
    IF EXISTS (SELECT * FROM [sys].[identity_columns] WHERE [name] IN (N'Id', N'Activo', N'CarreraODepartamento', N'Correo', N'FechaRegistro', N'NombreCompleto', N'PasswordHash', N'Rol', N'Telefono') AND [object_id] = OBJECT_ID(N'[Usuarios]'))
        SET IDENTITY_INSERT [Usuarios] OFF;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260922173855_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Comentarios_SolicitudId] ON [Comentarios] ([SolicitudId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260922173855_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Comentarios_UsuarioId] ON [Comentarios] ([UsuarioId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260922173855_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Evidencias_SolicitudId] ON [Evidencias] ([SolicitudId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260922173855_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Evidencias_SubidoPorId] ON [Evidencias] ([SubidoPorId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260922173855_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Recursos_Codigo] ON [Recursos] ([Codigo]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260922173855_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Solicitudes_AsignadoAId] ON [Solicitudes] ([AsignadoAId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260922173855_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Solicitudes_CodigoTicket] ON [Solicitudes] ([CodigoTicket]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260922173855_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Solicitudes_RecursoId] ON [Solicitudes] ([RecursoId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260922173855_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Solicitudes_SolicitanteId] ON [Solicitudes] ([SolicitanteId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260922173855_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Usuarios_Correo] ON [Usuarios] ([Correo]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260922173855_InitialCreate'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260922173855_InitialCreate', N'9.0.2');
END;

COMMIT;
GO

