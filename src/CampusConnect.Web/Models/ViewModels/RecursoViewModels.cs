using System.ComponentModel.DataAnnotations;
using CampusConnect.Web.Models.Entities;
using CampusConnect.Web.Models.Enums;

namespace CampusConnect.Web.Models.ViewModels;

public class RecursoIndexViewModel
{
    public List<Recurso> Recursos { get; set; } = new();

    public int TotalRecursos { get; set; }
    public int TotalDisponibles { get; set; }
    public int TotalEnMantenimiento { get; set; }
    public int TotalFueraDeServicio { get; set; }

    public string? Busqueda { get; set; }
    public TipoRecurso? TipoFiltro { get; set; }
    public EstadoRecurso? EstadoFiltro { get; set; }
}

public class RecursoFormViewModel
{
    public int Id { get; set; }

    [Required(ErrorMessage = "El código único del recurso es obligatorio.")]
    [MaxLength(50, ErrorMessage = "El código no puede tener más de 50 caracteres.")]
    [Display(Name = "Código")]
    public string Codigo { get; set; } = string.Empty;

    [Required(ErrorMessage = "El nombre del recurso es obligatorio.")]
    [MaxLength(150, ErrorMessage = "El nombre no puede tener más de 150 caracteres.")]
    [Display(Name = "Nombre")]
    public string Nombre { get; set; } = string.Empty;

    [Required(ErrorMessage = "El tipo de recurso es obligatorio.")]
    [Display(Name = "Tipo de Recurso")]
    public TipoRecurso Tipo { get; set; } = TipoRecurso.Equipamiento;

    [Required(ErrorMessage = "La ubicación es obligatoria.")]
    [MaxLength(150, ErrorMessage = "La ubicación no puede tener más de 150 caracteres.")]
    [Display(Name = "Ubicación (Edificio / Aula / Laboratorio)")]
    public string Ubicacion { get; set; } = string.Empty;

    [MaxLength(500, ErrorMessage = "La descripción no puede tener más de 500 caracteres.")]
    [Display(Name = "Descripción técnica")]
    public string? Descripcion { get; set; }

    [Required(ErrorMessage = "El estado es obligatorio.")]
    [Display(Name = "Estado Operativo")]
    public EstadoRecurso Estado { get; set; } = EstadoRecurso.Disponible;
}

public class RecursoDetailsViewModel
{
    public Recurso Recurso { get; set; } = null!;
    public List<Solicitud> SolicitudesRelacionadas { get; set; } = new();
}
