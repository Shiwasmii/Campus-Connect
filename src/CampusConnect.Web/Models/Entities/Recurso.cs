using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;
using CampusConnect.Web.Models.Enums;

namespace CampusConnect.Web.Models.Entities;

public class Recurso
{
    [Key]
    public int Id { get; set; }

    [Required]
    [MaxLength(50)]
    public string Codigo { get; set; } = string.Empty;

    [Required]
    [MaxLength(150)]
    public string Nombre { get; set; } = string.Empty;

    [Required]
    public TipoRecurso Tipo { get; set; } = TipoRecurso.Equipamiento;

    [Required]
    [MaxLength(150)]
    public string Ubicacion { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? Descripcion { get; set; }

    [Required]
    public EstadoRecurso Estado { get; set; } = EstadoRecurso.Disponible;

    public DateTime FechaRegistro { get; set; } = DateTime.UtcNow;

    // Relaciones de navegación
    [JsonIgnore]
    public virtual ICollection<Solicitud> Solicitudes { get; set; } = new List<Solicitud>();
}
