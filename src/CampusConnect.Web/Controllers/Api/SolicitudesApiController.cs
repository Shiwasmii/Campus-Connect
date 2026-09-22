using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CampusConnect.Web.Data;
using CampusConnect.Web.Models.DTOs;
using CampusConnect.Web.Models.Entities;
using CampusConnect.Web.Models.Enums;

namespace CampusConnect.Web.Controllers.Api;

[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class SolicitudesApiController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IWebHostEnvironment _environment;
    private readonly ILogger<SolicitudesApiController> _logger;

    public SolicitudesApiController(
        ApplicationDbContext context,
        IWebHostEnvironment environment,
        ILogger<SolicitudesApiController> logger)
    {
        _context = context;
        _environment = environment;
        _logger = logger;
    }

    /// <summary>
    /// Lista todas las solicitudes registradas (con filtros opcionales) para consumo de la app móvil.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(IEnumerable<SolicitudResumenDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IEnumerable<SolicitudResumenDto>>> ObtenerSolicitudes(
        [FromQuery] EstadoSolicitud? estado,
        [FromQuery] CategoriaSolicitud? categoria,
        [FromQuery] int? solicitanteId)
    {
        var query = _context.Solicitudes
            .Include(s => s.Solicitante)
            .Include(s => s.AsignadoA)
            .Include(s => s.Recurso)
            .AsNoTracking();

        if (estado.HasValue)
            query = query.Where(s => s.Estado == estado.Value);

        if (categoria.HasValue)
            query = query.Where(s => s.Categoria == categoria.Value);

        if (solicitanteId.HasValue)
            query = query.Where(s => s.SolicitanteId == solicitanteId.Value);

        var list = await query
            .OrderByDescending(s => s.FechaCreacion)
            .Select(s => new SolicitudResumenDto
            {
                Id = s.Id,
                CodigoTicket = s.CodigoTicket,
                Titulo = s.Titulo,
                Descripcion = s.Descripcion,
                Categoria = s.Categoria.ToString(),
                Prioridad = s.Prioridad.ToString(),
                Estado = s.Estado.ToString(),
                FechaCreacion = s.FechaCreacion,
                FechaActualizacion = s.FechaActualizacion,
                SolicitanteId = s.SolicitanteId,
                SolicitanteNombre = s.Solicitante != null ? s.Solicitante.NombreCompleto : "Desconocido",
                AsignadoANombre = s.AsignadoA != null ? s.AsignadoA.NombreCompleto : null,
                RecursoNombre = s.Recurso != null ? $"{s.Recurso.Codigo} - {s.Recurso.Nombre}" : null
            })
            .ToListAsync();

        return Ok(list);
    }

    /// <summary>
    /// Crea una nueva solicitud de servicio (Mantenimiento, Soporte Tecnológico, Infraestructura).
    /// </summary>
    [HttpPost]
    [ProducesResponseType(typeof(SolicitudResumenDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<SolicitudResumenDto>> CrearSolicitud([FromBody] CrearSolicitudDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var solicitanteExiste = await _context.Usuarios.AnyAsync(u => u.Id == dto.SolicitanteId && u.Activo);
        if (!solicitanteExiste)
            return BadRequest(new { mensaje = $"El solicitante con ID {dto.SolicitanteId} no existe o está inactivo." });

        if (dto.RecursoId.HasValue)
        {
            var recursoExiste = await _context.Recursos.AnyAsync(r => r.Id == dto.RecursoId.Value);
            if (!recursoExiste)
                return BadRequest(new { mensaje = $"El recurso con ID {dto.RecursoId.Value} no existe." });
        }

        // Generación de código de ticket correlativo único
        var prefijoFecha = DateTime.UtcNow.ToString("yyyyMM");
        var totalHoy = await _context.Solicitudes.CountAsync(s => s.CodigoTicket.StartsWith($"TKT-{prefijoFecha}"));
        var codigoTicket = $"TKT-{prefijoFecha}-{(totalHoy + 1):D4}";

        var solicitud = new Solicitud
        {
            CodigoTicket = codigoTicket,
            Titulo = dto.Titulo.Trim(),
            Descripcion = dto.Descripcion.Trim(),
            Categoria = dto.Categoria,
            Prioridad = dto.Prioridad,
            Estado = EstadoSolicitud.Pendiente,
            FechaCreacion = DateTime.UtcNow,
            SolicitanteId = dto.SolicitanteId,
            RecursoId = dto.RecursoId
        };

        _context.Solicitudes.Add(solicitud);
        await _context.SaveChangesAsync();

        _logger.LogInformation("Solicitud creada exitosamente: {CodigoTicket} por usuario {SolicitanteId}",
            solicitud.CodigoTicket, solicitud.SolicitanteId);

        // Retornar resumen
        var solicitante = await _context.Usuarios.FindAsync(solicitud.SolicitanteId);
        Recurso? recurso = null;
        if (solicitud.RecursoId.HasValue)
            recurso = await _context.Recursos.FindAsync(solicitud.RecursoId.Value);

        var respuestaDto = new SolicitudResumenDto
        {
            Id = solicitud.Id,
            CodigoTicket = solicitud.CodigoTicket,
            Titulo = solicitud.Titulo,
            Descripcion = solicitud.Descripcion,
            Categoria = solicitud.Categoria.ToString(),
            Prioridad = solicitud.Prioridad.ToString(),
            Estado = solicitud.Estado.ToString(),
            FechaCreacion = solicitud.FechaCreacion,
            FechaActualizacion = solicitud.FechaActualizacion,
            SolicitanteId = solicitud.SolicitanteId,
            SolicitanteNombre = solicitante?.NombreCompleto ?? "Desconocido",
            RecursoNombre = recurso != null ? $"{recurso.Codigo} - {recurso.Nombre}" : null
        };

        return CreatedAtAction(nameof(ConsultarSeguimiento), new { id = solicitud.Id }, respuestaDto);
    }

    /// <summary>
    /// Adjunta un archivo de evidencia (imagen, documento) a una solicitud existente.
    /// </summary>
    [HttpPost("{id:int}/evidencias")]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(EvidenciaDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<EvidenciaDto>> AdjuntarEvidencia(
        [FromRoute] int id,
        [FromForm] IFormFile archivo,
        [FromForm] int subidoPorId)
    {
        if (archivo == null || archivo.Length == 0)
            return BadRequest(new { mensaje = "Debe proporcionar un archivo válido como evidencia." });

        // Límite de tamaño: 20 MB
        if (archivo.Length > 20 * 1024 * 1024)
            return BadRequest(new { mensaje = "El archivo excede el tamaño máximo permitido de 20MB." });

        var solicitud = await _context.Solicitudes.FindAsync(id);
        if (solicitud == null)
            return NotFound(new { mensaje = $"No se encontró la solicitud con ID {id}." });

        var usuario = await _context.Usuarios.FindAsync(subidoPorId);
        if (usuario == null)
            return BadRequest(new { mensaje = $"El usuario con ID {subidoPorId} no existe." });

        // Preparar carpeta física en wwwroot/uploads/evidencias
        var uploadsFolder = Path.Combine(_environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot"), "uploads", "evidencias");
        if (!Directory.Exists(uploadsFolder))
        {
            Directory.CreateDirectory(uploadsFolder);
        }

        var extension = Path.GetExtension(archivo.FileName).ToLowerInvariant();
        var nombreAlmacenado = $"{Guid.NewGuid()}{extension}";
        var rutaFisicaCompleta = Path.Combine(uploadsFolder, nombreAlmacenado);

        using (var stream = new FileStream(rutaFisicaCompleta, FileMode.Create))
        {
            await archivo.CopyToAsync(stream);
        }

        var rutaRelativa = $"/uploads/evidencias/{nombreAlmacenado}";

        var evidencia = new Evidencia
        {
            NombreArchivoOriginal = Path.GetFileName(archivo.FileName),
            NombreAlmacenado = nombreAlmacenado,
            RutaRelativa = rutaRelativa,
            ContentType = string.IsNullOrWhiteSpace(archivo.ContentType) ? "application/octet-stream" : archivo.ContentType,
            TamanoBytes = archivo.Length,
            FechaSubida = DateTime.UtcNow,
            SolicitudId = id,
            SubidoPorId = subidoPorId
        };

        _context.Evidencias.Add(evidencia);
        solicitud.FechaActualizacion = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        _logger.LogInformation("Evidencia {Id} adjuntada a solicitud {SolicitudId} por usuario {UsuarioId}",
            evidencia.Id, id, subidoPorId);

        var respuesta = new EvidenciaDto
        {
            Id = evidencia.Id,
            NombreArchivoOriginal = evidencia.NombreArchivoOriginal,
            UrlDescarga = evidencia.RutaRelativa,
            ContentType = evidencia.ContentType,
            TamanoBytes = evidencia.TamanoBytes,
            FechaSubida = evidencia.FechaSubida,
            SubidoPorId = usuario.Id,
            SubidoPorNombre = usuario.NombreCompleto
        };

        return CreatedAtAction(nameof(ConsultarSeguimiento), new { id }, respuesta);
    }

    /// <summary>
    /// Consulta el estado y seguimiento integral de una solicitud, incluyendo historial de comentarios y evidencias adjuntas.
    /// </summary>
    [HttpGet("{id:int}/seguimiento")]
    [ProducesResponseType(typeof(SeguimientoSolicitudDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<SeguimientoSolicitudDto>> ConsultarSeguimiento([FromRoute] int id)
    {
        var solicitud = await _context.Solicitudes
            .Include(s => s.Solicitante)
            .Include(s => s.AsignadoA)
            .Include(s => s.Recurso)
            .Include(s => s.Comentarios)
                .ThenInclude(c => c.Usuario)
            .Include(s => s.Evidencias)
                .ThenInclude(e => e.SubidoPor)
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == id);

        if (solicitud == null)
            return NotFound(new { mensaje = $"No se encontró la solicitud con ID {id}." });

        var dto = new SeguimientoSolicitudDto
        {
            Id = solicitud.Id,
            CodigoTicket = solicitud.CodigoTicket,
            Titulo = solicitud.Titulo,
            Descripcion = solicitud.Descripcion,
            Categoria = solicitud.Categoria.ToString(),
            Prioridad = solicitud.Prioridad.ToString(),
            Estado = solicitud.Estado.ToString(),
            FechaCreacion = solicitud.FechaCreacion,
            FechaActualizacion = solicitud.FechaActualizacion,
            FechaCierre = solicitud.FechaCierre,
            Solicitante = new UsuarioInfo
            {
                Id = solicitud.Solicitante?.Id ?? 0,
                NombreCompleto = solicitud.Solicitante?.NombreCompleto ?? "No especificado",
                Correo = solicitud.Solicitante?.Correo ?? string.Empty,
                Rol = solicitud.Solicitante?.Rol.ToString() ?? string.Empty
            },
            AsignadoA = solicitud.AsignadoA != null
                ? new UsuarioInfo
                {
                    Id = solicitud.AsignadoA.Id,
                    NombreCompleto = solicitud.AsignadoA.NombreCompleto,
                    Correo = solicitud.AsignadoA.Correo,
                    Rol = solicitud.AsignadoA.Rol.ToString()
                }
                : null,
            Recurso = solicitud.Recurso != null
                ? new RecursoInfo
                {
                    Id = solicitud.Recurso.Id,
                    Codigo = solicitud.Recurso.Codigo,
                    Nombre = solicitud.Recurso.Nombre,
                    Tipo = solicitud.Recurso.Tipo.ToString(),
                    Ubicacion = solicitud.Recurso.Ubicacion,
                    Estado = solicitud.Recurso.Estado.ToString()
                }
                : null,
            Comentarios = solicitud.Comentarios
                .OrderBy(c => c.FechaCreacion)
                .Select(c => new ComentarioDto
                {
                    Id = c.Id,
                    Mensaje = c.Mensaje,
                    FechaCreacion = c.FechaCreacion,
                    EsInterno = c.EsInterno,
                    UsuarioId = c.UsuarioId,
                    UsuarioNombre = c.Usuario?.NombreCompleto ?? "Usuario",
                    UsuarioRol = c.Usuario?.Rol.ToString() ?? string.Empty
                })
                .ToList(),
            Evidencias = solicitud.Evidencias
                .OrderByDescending(e => e.FechaSubida)
                .Select(e => new EvidenciaDto
                {
                    Id = e.Id,
                    NombreArchivoOriginal = e.NombreArchivoOriginal,
                    UrlDescarga = e.RutaRelativa,
                    ContentType = e.ContentType,
                    TamanoBytes = e.TamanoBytes,
                    FechaSubida = e.FechaSubida,
                    SubidoPorId = e.SubidoPorId,
                    SubidoPorNombre = e.SubidoPor?.NombreCompleto ?? "Usuario"
                })
                .ToList()
        };

        return Ok(dto);
    }

    /// <summary>
    /// Agrega un nuevo comentario a la bitácora de seguimiento de la solicitud.
    /// </summary>
    [HttpPost("{id:int}/comentarios")]
    [ProducesResponseType(typeof(ComentarioDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ComentarioDto>> AgregarComentario(
        [FromRoute] int id,
        [FromBody] CrearComentarioDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var solicitud = await _context.Solicitudes.FindAsync(id);
        if (solicitud == null)
            return NotFound(new { mensaje = $"No se encontró la solicitud con ID {id}." });

        var usuario = await _context.Usuarios.FindAsync(dto.UsuarioId);
        if (usuario == null)
            return BadRequest(new { mensaje = $"El usuario con ID {dto.UsuarioId} no existe." });

        var comentario = new Comentario
        {
            Mensaje = dto.Mensaje.Trim(),
            FechaCreacion = DateTime.UtcNow,
            EsInterno = dto.EsInterno,
            SolicitudId = id,
            UsuarioId = dto.UsuarioId
        };

        _context.Comentarios.Add(comentario);
        solicitud.FechaActualizacion = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        var respuesta = new ComentarioDto
        {
            Id = comentario.Id,
            Mensaje = comentario.Mensaje,
            FechaCreacion = comentario.FechaCreacion,
            EsInterno = comentario.EsInterno,
            UsuarioId = usuario.Id,
            UsuarioNombre = usuario.NombreCompleto,
            UsuarioRol = usuario.Rol.ToString()
        };

        return CreatedAtAction(nameof(ConsultarSeguimiento), new { id }, respuesta);
    }
}
