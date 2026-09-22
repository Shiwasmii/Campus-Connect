using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace CampusConnect.Web.Models.Entities;

public class Comentario
{
    [Key]
    public int Id { get; set; }

    [Required]
    public string Mensaje { get; set; } = string.Empty;

    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;

    public bool EsInterno { get; set; } = false;

    [Required]
    public int SolicitudId { get; set; }

    [JsonIgnore]
    [ForeignKey(nameof(SolicitudId))]
    public virtual Solicitud? Solicitud { get; set; }

    [Required]
    public int UsuarioId { get; set; }

    [ForeignKey(nameof(UsuarioId))]
    public virtual Usuario? Usuario { get; set; }
}
