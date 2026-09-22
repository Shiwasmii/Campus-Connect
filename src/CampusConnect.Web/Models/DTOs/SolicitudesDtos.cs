using System.ComponentModel.DataAnnotations;
using CampusConnect.Web.Models.Enums;

namespace CampusConnect.Web.Models.DTOs;

public class CrearSolicitudDto
{
    [Required(ErrorMessage = "El título es obligatorio.")]
    [MaxLength(200, ErrorMessage = "El título no puede exceder los 200 caracteres.")]
    public string Titulo { get; set; } = string.Empty;

    [Required(ErrorMessage = "La descripción detallada es obligatoria.")]
    public string Descripcion { get; set; } = string.Empty;

    [Required(ErrorMessage = "La categoría es obligatoria.")]
    public CategoriaSolicitud Categoria { get; set; }

    [Required(ErrorMessage = "La prioridad es obligatoria.")]
    public PrioridadSolicitud Prioridad { get; set; } = PrioridadSolicitud.Media;

    [Required(ErrorMessage = "El identificador del solicitante es obligatorio.")]
    public int SolicitanteId { get; set; }

    public int? RecursoId { get; set; }
}

public class AdjuntarEvidenciaRequest
{
    [Required(ErrorMessage = "El identificador del usuario que sube el archivo es obligatorio.")]
    public int SubidoPorId { get; set; }
}

public class CrearComentarioDto
{
    [Required(ErrorMessage = "El mensaje del comentario es obligatorio.")]
    public string Mensaje { get; set; } = string.Empty;

    [Required(ErrorMessage = "El identificador del usuario es obligatorio.")]
    public int UsuarioId { get; set; }

    public bool EsInterno { get; set; } = false;
}

public class SolicitudResumenDto
{
    public int Id { get; set; }
    public string CodigoTicket { get; set; } = string.Empty;
    public string Titulo { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
    public string Categoria { get; set; } = string.Empty;
    public string Prioridad { get; set; } = string.Empty;
    public string Estado { get; set; } = string.Empty;
    public DateTime FechaCreacion { get; set; }
    public DateTime? FechaActualizacion { get; set; }
    public int SolicitanteId { get; set; }
    public string SolicitanteNombre { get; set; } = string.Empty;
    public string? AsignadoANombre { get; set; }
    public string? RecursoNombre { get; set; }
}

public class SeguimientoSolicitudDto
{
    public int Id { get; set; }
    public string CodigoTicket { get; set; } = string.Empty;
    public string Titulo { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
    public string Categoria { get; set; } = string.Empty;
    public string Prioridad { get; set; } = string.Empty;
    public string Estado { get; set; } = string.Empty;
    public DateTime FechaCreacion { get; set; }
    public DateTime? FechaActualizacion { get; set; }
    public DateTime? FechaCierre { get; set; }

    public UsuarioInfo Solicitante { get; set; } = new();
    public UsuarioInfo? AsignadoA { get; set; }
    public RecursoInfo? Recurso { get; set; }

    public List<ComentarioDto> Comentarios { get; set; } = new();
    public List<EvidenciaDto> Evidencias { get; set; } = new();
}

public class UsuarioInfo
{
    public int Id { get; set; }
    public string NombreCompleto { get; set; } = string.Empty;
    public string Correo { get; set; } = string.Empty;
    public string Rol { get; set; } = string.Empty;
}

public class RecursoInfo
{
    public int Id { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string Nombre { get; set; } = string.Empty;
    public string Tipo { get; set; } = string.Empty;
    public string Ubicacion { get; set; } = string.Empty;
    public string Estado { get; set; } = string.Empty;
}

public class ComentarioDto
{
    public int Id { get; set; }
    public string Mensaje { get; set; } = string.Empty;
    public DateTime FechaCreacion { get; set; }
    public bool EsInterno { get; set; }
    public int UsuarioId { get; set; }
    public string UsuarioNombre { get; set; } = string.Empty;
    public string UsuarioRol { get; set; } = string.Empty;
}

public class EvidenciaDto
{
    public int Id { get; set; }
    public string NombreArchivoOriginal { get; set; } = string.Empty;
    public string UrlDescarga { get; set; } = string.Empty;
    public string ContentType { get; set; } = string.Empty;
    public long TamanoBytes { get; set; }
    public DateTime FechaSubida { get; set; }
    public int SubidoPorId { get; set; }
    public string SubidoPorNombre { get; set; } = string.Empty;
}
