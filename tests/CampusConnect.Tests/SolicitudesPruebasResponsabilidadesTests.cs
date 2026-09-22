using System.Text;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Moq;
using CampusConnect.Web.Controllers.Api;
using CampusConnect.Web.Models.DTOs;
using CampusConnect.Web.Models.Entities;
using CampusConnect.Web.Models.Enums;
using Xunit;

namespace CampusConnect.Tests;

public class SolicitudesPruebasResponsabilidadesTests
{
    private readonly Mock<IWebHostEnvironment> _mockEnvironment;
    private readonly Mock<ILogger<SolicitudesApiController>> _mockSolicitudesLogger;
    private readonly Mock<ILogger<AuthApiController>> _mockAuthLogger;
    private readonly string _tempDirectory;

    public SolicitudesPruebasResponsabilidadesTests()
    {
        _tempDirectory = Path.Combine(Path.GetTempPath(), "CampusConnectTestUploads_" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(_tempDirectory);

        _mockEnvironment = new Mock<IWebHostEnvironment>();
        _mockEnvironment.Setup(m => m.WebRootPath).Returns(_tempDirectory);

        _mockSolicitudesLogger = new Mock<ILogger<SolicitudesApiController>>();
        _mockAuthLogger = new Mock<ILogger<AuthApiController>>();
    }

    /// <summary>
    /// PRUEBA 1: Verificar el inicio de sesión exitoso con credenciales válidas.
    /// </summary>
    [Fact]
    public async Task Prueba1_InicioDeSesionExitoso_RetornaOkConPerfilUsuario()
    {
        // Arrange
        using var context = TestDbContextFactory.CreateInMemoryDbContext();
        var controller = new AuthApiController(context, _mockAuthLogger.Object);

        var loginDto = new LoginRequestDto
        {
            Correo = "juan.perez@universidad.edu",
            Password = "password123"
        };

        // Act
        var result = await controller.IniciarSesion(loginDto);

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<LoginResponseDto>(okResult.Value);

        Assert.True(response.Exitoso);
        Assert.NotNull(response.Usuario);
        Assert.Equal("juan.perez@universidad.edu", response.Usuario.Correo);
        Assert.Equal("Estudiante", response.Usuario.Rol);
        Assert.False(string.IsNullOrWhiteSpace(response.TokenSimulado));
    }

    /// <summary>
    /// PRUEBA 2: Crear solicitud (Validación y persistencia a nivel de API/Controlador).
    /// </summary>
    [Fact]
    public async Task Prueba2_CrearSolicitud_ValidacionNivelApi_PersisteYRetorna201Created()
    {
        // Arrange
        using var context = TestDbContextFactory.CreateInMemoryDbContext();
        var controller = new SolicitudesApiController(context, _mockEnvironment.Object, _mockSolicitudesLogger.Object);

        var nuevaSolicitud = new CrearSolicitudDto
        {
            Titulo = "Falla de red en Laboratorio 1",
            Descripcion = "Las computadoras no obtienen dirección IP ni tienen acceso a internet.",
            Categoria = CategoriaSolicitud.SoporteTecnologico,
            Prioridad = PrioridadSolicitud.Alta,
            SolicitanteId = 1,
            RecursoId = 1
        };

        // Act
        var result = await controller.CrearSolicitud(nuevaSolicitud);

        // Assert
        var createdAtResult = Assert.IsType<CreatedAtActionResult>(result.Result);
        var resumen = Assert.IsType<SolicitudResumenDto>(createdAtResult.Value);

        Assert.True(resumen.Id > 0);
        Assert.StartsWith("TKT-", resumen.CodigoTicket);
        Assert.Equal("Falla de red en Laboratorio 1", resumen.Titulo);
        Assert.Equal(EstadoSolicitud.Pendiente.ToString(), resumen.Estado);
        Assert.Equal(PrioridadSolicitud.Alta.ToString(), resumen.Prioridad);

        // Verificar que se guardó en la base de datos
        var enBaseDeDatos = await context.Solicitudes.FindAsync(resumen.Id);
        Assert.NotNull(enBaseDeDatos);
        Assert.Equal(1, enBaseDeDatos.SolicitanteId);
    }

    /// <summary>
    /// PRUEBA 3: Adjuntar evidencia a una solicitud existente.
    /// </summary>
    [Fact]
    public async Task Prueba3_AdjuntarEvidencia_SolicitudExistente_GuardaArchivoYRegistraEnDb()
    {
        // Arrange
        using var context = TestDbContextFactory.CreateInMemoryDbContext();
        var controller = new SolicitudesApiController(context, _mockEnvironment.Object, _mockSolicitudesLogger.Object);

        var solicitud = new Solicitud
        {
            CodigoTicket = "TKT-2026-TEST1",
            Titulo = "Pantalla rota",
            Descripcion = "Equipo con pantalla estrellada",
            Categoria = CategoriaSolicitud.Mantenimiento,
            Prioridad = PrioridadSolicitud.Media,
            Estado = EstadoSolicitud.Pendiente,
            SolicitanteId = 1
        };
        context.Solicitudes.Add(solicitud);
        await context.SaveChangesAsync();

        // Simular archivo IFormFile
        var contenido = "Contenido binario simulado de una imagen PNG";
        var bytes = Encoding.UTF8.GetBytes(contenido);
        using var stream = new MemoryStream(bytes);
        var archivoMock = new FormFile(stream, 0, bytes.Length, "archivo", "evidencia_pantalla.png")
        {
            Headers = new HeaderDictionary(),
            ContentType = "image/png"
        };

        // Act
        var result = await controller.AdjuntarEvidencia(solicitud.Id, archivoMock, subidoPorId: 1);

        // Assert
        var createdAtResult = Assert.IsType<CreatedAtActionResult>(result.Result);
        var evidenciaDto = Assert.IsType<EvidenciaDto>(createdAtResult.Value);

        Assert.True(evidenciaDto.Id > 0);
        Assert.Equal("evidencia_pantalla.png", evidenciaDto.NombreArchivoOriginal);
        Assert.Equal("image/png", evidenciaDto.ContentType);
        Assert.Equal(bytes.Length, evidenciaDto.TamanoBytes);

        // Verificar persistencia en base de datos
        var enDb = await context.Evidencias.FindAsync(evidenciaDto.Id);
        Assert.NotNull(enDb);
        Assert.Equal(solicitud.Id, enDb.SolicitudId);
    }

    /// <summary>
    /// PRUEBA 4: Consultar el seguimiento de una solicitud (obtener solicitud con sus detalles).
    /// </summary>
    [Fact]
    public async Task Prueba4_ConsultarSeguimiento_SolicitudExistente_RetornaDetalleCompleto()
    {
        // Arrange
        using var context = TestDbContextFactory.CreateInMemoryDbContext();
        var controller = new SolicitudesApiController(context, _mockEnvironment.Object, _mockSolicitudesLogger.Object);

        var solicitud = new Solicitud
        {
            CodigoTicket = "TKT-2026-SEGUIMIENTO",
            Titulo = "Proyector no enciende",
            Descripcion = "El proyector del aula no responde al botón de encendido",
            Categoria = CategoriaSolicitud.SoporteTecnologico,
            Prioridad = PrioridadSolicitud.Urgente,
            Estado = EstadoSolicitud.EnProceso,
            SolicitanteId = 1,
            AsignadoAId = 3,
            RecursoId = 1,
            FechaCreacion = DateTime.UtcNow
        };
        context.Solicitudes.Add(solicitud);
        await context.SaveChangesAsync();

        // Act
        var result = await controller.ConsultarSeguimiento(solicitud.Id);

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var seguimientoDto = Assert.IsType<SeguimientoSolicitudDto>(okResult.Value);

        Assert.Equal(solicitud.Id, seguimientoDto.Id);
        Assert.Equal("TKT-2026-SEGUIMIENTO", seguimientoDto.CodigoTicket);
        Assert.Equal(EstadoSolicitud.EnProceso.ToString(), seguimientoDto.Estado);
        Assert.Equal(PrioridadSolicitud.Urgente.ToString(), seguimientoDto.Prioridad);
        Assert.NotNull(seguimientoDto.Solicitante);
        Assert.Equal("Estudiante Juan Pérez", seguimientoDto.Solicitante.NombreCompleto);
        Assert.NotNull(seguimientoDto.AsignadoA);
        Assert.Equal("Técnico Carlos Rivas", seguimientoDto.AsignadoA.NombreCompleto);
        Assert.NotNull(seguimientoDto.Recurso);
        Assert.Equal("LAB-SIS-01", seguimientoDto.Recurso.Codigo);
    }

    /// <summary>
    /// PRUEBA 5: Visualizar comentarios de una solicitud (bitácora de trazabilidad).
    /// </summary>
    [Fact]
    public async Task Prueba5_VisualizarComentarios_SolicitudConComentarios_RetornaHistorialCronologico()
    {
        // Arrange
        using var context = TestDbContextFactory.CreateInMemoryDbContext();
        var controller = new SolicitudesApiController(context, _mockEnvironment.Object, _mockSolicitudesLogger.Object);

        var solicitud = new Solicitud
        {
            CodigoTicket = "TKT-2026-COMENTARIOS",
            Titulo = "Aire acondicionado gotea",
            Descripcion = "Gotera constante sobre la mesa del docente",
            Categoria = CategoriaSolicitud.Infraestructura,
            Prioridad = PrioridadSolicitud.Media,
            Estado = EstadoSolicitud.EnProceso,
            SolicitanteId = 1,
            FechaCreacion = DateTime.UtcNow.AddHours(-2)
        };
        context.Solicitudes.Add(solicitud);
        await context.SaveChangesAsync();

        // Agregar 2 comentarios a la solicitud
        var com1 = new Comentario
        {
            SolicitudId = solicitud.Id,
            UsuarioId = 1,
            Mensaje = "Adjunto aviso: la gotera aumentó de frecuencia.",
            FechaCreacion = DateTime.UtcNow.AddHours(-1)
        };
        var com2 = new Comentario
        {
            SolicitudId = solicitud.Id,
            UsuarioId = 3,
            Mensaje = "Técnico en camino con refacciones para inspección.",
            FechaCreacion = DateTime.UtcNow.AddMinutes(-30)
        };
        context.Comentarios.AddRange(com1, com2);
        await context.SaveChangesAsync();

        // Act
        var result = await controller.ConsultarSeguimiento(solicitud.Id);

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var seguimientoDto = Assert.IsType<SeguimientoSolicitudDto>(okResult.Value);

        Assert.NotNull(seguimientoDto.Comentarios);
        Assert.Equal(2, seguimientoDto.Comentarios.Count);
        Assert.Equal("Adjunto aviso: la gotera aumentó de frecuencia.", seguimientoDto.Comentarios[0].Mensaje);
        Assert.Equal("Estudiante Juan Pérez", seguimientoDto.Comentarios[0].UsuarioNombre);
        Assert.Equal("Técnico en camino con refacciones para inspección.", seguimientoDto.Comentarios[1].Mensaje);
        Assert.Equal("Técnico Carlos Rivas", seguimientoDto.Comentarios[1].UsuarioNombre);
    }
}
