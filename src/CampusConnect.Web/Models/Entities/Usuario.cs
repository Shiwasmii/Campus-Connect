using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;
using CampusConnect.Web.Models.Enums;

namespace CampusConnect.Web.Models.Entities;

public class Usuario
{
    [Key]
    public int Id { get; set; }

    [Required]
    [MaxLength(150)]
    public string NombreCompleto { get; set; } = string.Empty;

    [Required]
    [MaxLength(100)]
    [EmailAddress]
    public string Correo { get; set; } = string.Empty;

    [Required]
    [MaxLength(255)]
    [JsonIgnore]
    public string PasswordHash { get; set; } = string.Empty;

    [Required]
    public RolUsuario Rol { get; set; } = RolUsuario.Estudiante;

    [MaxLength(20)]
    public string? Telefono { get; set; }

    [MaxLength(150)]
    public string? CarreraODepartamento { get; set; }

    public DateTime FechaRegistro { get; set; } = DateTime.UtcNow;

    public bool Activo { get; set; } = true;

    // Relaciones de navegación
    [JsonIgnore]
    [InverseProperty(nameof(Solicitud.Solicitante))]
    public virtual ICollection<Solicitud> SolicitudesCreadas { get; set; } = new List<Solicitud>();

    [JsonIgnore]
    [InverseProperty(nameof(Solicitud.AsignadoA))]
    public virtual ICollection<Solicitud> SolicitudesAsignadas { get; set; } = new List<Solicitud>();

    [JsonIgnore]
    public virtual ICollection<Comentario> Comentarios { get; set; } = new List<Comentario>();

    [JsonIgnore]
    public virtual ICollection<Evidencia> Evidencias { get; set; } = new List<Evidencia>();
}
