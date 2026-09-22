using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;
using CampusConnect.Web.Models.Enums;

namespace CampusConnect.Web.Models.Entities;

public class Solicitud
{
    [Key]
    public int Id { get; set; }

    [Required]
    [MaxLength(20)]
    public string CodigoTicket { get; set; } = string.Empty;

    [Required]
    [MaxLength(200)]
    public string Titulo { get; set; } = string.Empty;

    [Required]
    public string Descripcion { get; set; } = string.Empty;

    [Required]
    public CategoriaSolicitud Categoria { get; set; } = CategoriaSolicitud.SoporteTecnologico;

    [Required]
    public PrioridadSolicitud Prioridad { get; set; } = PrioridadSolicitud.Media;

    [Required]
    public EstadoSolicitud Estado { get; set; } = EstadoSolicitud.Pendiente;

    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;

    public DateTime? FechaActualizacion { get; set; }

    public DateTime? FechaCierre { get; set; }

    // Relación con Solicitante
    [Required]
    public int SolicitanteId { get; set; }

    [ForeignKey(nameof(SolicitanteId))]
    public virtual Usuario? Solicitante { get; set; }

    // Relación con Administrativo / Técnico asignado
    public int? AsignadoAId { get; set; }

    [ForeignKey(nameof(AsignadoAId))]
    public virtual Usuario? AsignadoA { get; set; }

    // Relación opcional con Recurso físico / equipamiento
    public int? RecursoId { get; set; }

    [ForeignKey(nameof(RecursoId))]
    public virtual Recurso? Recurso { get; set; }

    // Navegación a evidencias y comentarios
    public virtual ICollection<Evidencia> Evidencias { get; set; } = new List<Evidencia>();

    public virtual ICollection<Comentario> Comentarios { get; set; } = new List<Comentario>();
}
