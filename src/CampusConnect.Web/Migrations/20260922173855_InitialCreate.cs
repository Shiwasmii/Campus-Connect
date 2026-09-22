using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace CampusConnect.Web.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Recursos",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Codigo = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Nombre = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: false),
                    Tipo = table.Column<int>(type: "int", nullable: false),
                    Ubicacion = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: false),
                    Descripcion = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    Estado = table.Column<int>(type: "int", nullable: false),
                    FechaRegistro = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Recursos", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Usuarios",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    NombreCompleto = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: false),
                    Correo = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    PasswordHash = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    Rol = table.Column<int>(type: "int", nullable: false),
                    Telefono = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: true),
                    CarreraODepartamento = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: true),
                    FechaRegistro = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Activo = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Usuarios", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Solicitudes",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CodigoTicket = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    Titulo = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Descripcion = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Categoria = table.Column<int>(type: "int", nullable: false),
                    Prioridad = table.Column<int>(type: "int", nullable: false),
                    Estado = table.Column<int>(type: "int", nullable: false),
                    FechaCreacion = table.Column<DateTime>(type: "datetime2", nullable: false),
                    FechaActualizacion = table.Column<DateTime>(type: "datetime2", nullable: true),
                    FechaCierre = table.Column<DateTime>(type: "datetime2", nullable: true),
                    SolicitanteId = table.Column<int>(type: "int", nullable: false),
                    AsignadoAId = table.Column<int>(type: "int", nullable: true),
                    RecursoId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Solicitudes", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Solicitudes_Recursos_RecursoId",
                        column: x => x.RecursoId,
                        principalTable: "Recursos",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_Solicitudes_Usuarios_AsignadoAId",
                        column: x => x.AsignadoAId,
                        principalTable: "Usuarios",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Solicitudes_Usuarios_SolicitanteId",
                        column: x => x.SolicitanteId,
                        principalTable: "Usuarios",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "Comentarios",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Mensaje = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    FechaCreacion = table.Column<DateTime>(type: "datetime2", nullable: false),
                    EsInterno = table.Column<bool>(type: "bit", nullable: false),
                    SolicitudId = table.Column<int>(type: "int", nullable: false),
                    UsuarioId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Comentarios", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Comentarios_Solicitudes_SolicitudId",
                        column: x => x.SolicitudId,
                        principalTable: "Solicitudes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Comentarios_Usuarios_UsuarioId",
                        column: x => x.UsuarioId,
                        principalTable: "Usuarios",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "Evidencias",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    NombreArchivoOriginal = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    NombreAlmacenado = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    RutaRelativa = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    ContentType = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    TamanoBytes = table.Column<long>(type: "bigint", nullable: false),
                    FechaSubida = table.Column<DateTime>(type: "datetime2", nullable: false),
                    SolicitudId = table.Column<int>(type: "int", nullable: false),
                    SubidoPorId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Evidencias", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Evidencias_Solicitudes_SolicitudId",
                        column: x => x.SolicitudId,
                        principalTable: "Solicitudes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Evidencias_Usuarios_SubidoPorId",
                        column: x => x.SubidoPorId,
                        principalTable: "Usuarios",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.InsertData(
                table: "Recursos",
                columns: new[] { "Id", "Codigo", "Descripcion", "Estado", "FechaRegistro", "Nombre", "Tipo", "Ubicacion" },
                values: new object[,]
                {
                    { 1, "LAB-SIS-05", "PC de desarrollo para asignaturas de desarrollo y bases de datos", 1, new DateTime(2026, 1, 15, 8, 0, 0, 0, DateTimeKind.Utc), "Equipo de Cómputo Dell Core i7", 2, "Edificio A - Laboratorio de Sistemas 1" },
                    { 2, "AUD-PROY-01", "Sistema de proyección para conferencias y ponencias", 1, new DateTime(2026, 1, 15, 8, 0, 0, 0, DateTimeKind.Utc), "Proyector Láser Epson 4K", 2, "Edificio Central - Auditorio Mayor" },
                    { 3, "AULA-204-CLIMA", "Climatización de 24,000 BTU", 1, new DateTime(2026, 1, 15, 8, 0, 0, 0, DateTimeKind.Utc), "Unidad Central de Aire Acondicionado", 1, "Edificio B - Aula Magna 204" }
                });

            migrationBuilder.InsertData(
                table: "Usuarios",
                columns: new[] { "Id", "Activo", "CarreraODepartamento", "Correo", "FechaRegistro", "NombreCompleto", "PasswordHash", "Rol", "Telefono" },
                values: new object[,]
                {
                    { 1, true, "Ingeniería de Sistemas", "juan.perez@universidad.edu", new DateTime(2026, 1, 15, 8, 0, 0, 0, DateTimeKind.Utc), "Juan Pérez (Estudiante)", "hashed_secret_password_123", 1, "555-0101" },
                    { 2, true, "Dirección de Infraestructura y Servicios", "maria.gomez@universidad.edu", new DateTime(2026, 1, 15, 8, 0, 0, 0, DateTimeKind.Utc), "Dra. María Gómez (Administradora)", "hashed_secret_admin_123", 2, "555-0202" },
                    { 3, true, "Centro de Tecnologías de Información", "carlos.rivas@universidad.edu", new DateTime(2026, 1, 15, 8, 0, 0, 0, DateTimeKind.Utc), "Ing. Carlos Rivas (Soporte TI)", "hashed_secret_tech_123", 3, "555-0303" }
                });

            migrationBuilder.CreateIndex(
                name: "IX_Comentarios_SolicitudId",
                table: "Comentarios",
                column: "SolicitudId");

            migrationBuilder.CreateIndex(
                name: "IX_Comentarios_UsuarioId",
                table: "Comentarios",
                column: "UsuarioId");

            migrationBuilder.CreateIndex(
                name: "IX_Evidencias_SolicitudId",
                table: "Evidencias",
                column: "SolicitudId");

            migrationBuilder.CreateIndex(
                name: "IX_Evidencias_SubidoPorId",
                table: "Evidencias",
                column: "SubidoPorId");

            migrationBuilder.CreateIndex(
                name: "IX_Recursos_Codigo",
                table: "Recursos",
                column: "Codigo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Solicitudes_AsignadoAId",
                table: "Solicitudes",
                column: "AsignadoAId");

            migrationBuilder.CreateIndex(
                name: "IX_Solicitudes_CodigoTicket",
                table: "Solicitudes",
                column: "CodigoTicket",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Solicitudes_RecursoId",
                table: "Solicitudes",
                column: "RecursoId");

            migrationBuilder.CreateIndex(
                name: "IX_Solicitudes_SolicitanteId",
                table: "Solicitudes",
                column: "SolicitanteId");

            migrationBuilder.CreateIndex(
                name: "IX_Usuarios_Correo",
                table: "Usuarios",
                column: "Correo",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Comentarios");

            migrationBuilder.DropTable(
                name: "Evidencias");

            migrationBuilder.DropTable(
                name: "Solicitudes");

            migrationBuilder.DropTable(
                name: "Recursos");

            migrationBuilder.DropTable(
                name: "Usuarios");
        }
    }
}
