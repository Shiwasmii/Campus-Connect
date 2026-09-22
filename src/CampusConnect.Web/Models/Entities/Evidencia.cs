using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace CampusConnect.Web.Models.Entities;

public class Evidencia
{
    [Key]
    public int Id { get; set; }

    [Required]
    [MaxLength(255)]
    public string NombreArchivoOriginal { get; set; } = string.Empty;

    [Required]
    [MaxLength(255)]
    public string NombreAlmacenado { get; set; } = string.Empty;

    [Required]
    [MaxLength(500)]
    public string RutaRelativa { get; set; } = string.Empty;

    [Required]
    [MaxLength(100)]
    public string ContentType { get; set; } = string.Empty;

    public long TamanoBytes { get; set; }

    public DateTime FechaSubida { get; set; } = DateTime.UtcNow;

    [Required]
    public int SolicitudId { get; set; }

    [JsonIgnore]
    [ForeignKey(nameof(SolicitudId))]
    public virtual Solicitud? Solicitud { get; set; }

    [Required]
    public int SubidoPorId { get; set; }

    [ForeignKey(nameof(SubidoPorId))]
    public virtual Usuario? SubidoPor { get; set; }
}
