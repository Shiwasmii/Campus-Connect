using Microsoft.AspNetCore.Mvc.Rendering;
using CampusConnect.Web.Models.Entities;
using CampusConnect.Web.Models.Enums;

namespace CampusConnect.Web.Models.ViewModels;

public class DashboardViewModel
{
    // Métricas clave (KPIs)
    public int TotalSolicitudes { get; set; }
    public int PendientesCount { get; set; }
    public int EnProcesoCount { get; set; }
    public int AtendidasCount { get; set; }
    public int UrgentesSinAtenderCount { get; set; }

    // Filtros seleccionados
    public string? Busqueda { get; set; }
    public EstadoSolicitud? EstadoFiltro { get; set; }
    public PrioridadSolicitud? PrioridadFiltro { get; set; }
    public CategoriaSolicitud? CategoriaFiltro { get; set; }

    // Listados
    public List<SolicitudDashboardItem> Solicitudes { get; set; } = new();
    public List<SelectListItem> PersonalSoporteList { get; set; } = new();
}

public class SolicitudDashboardItem
{
    public int Id { get; set; }
    public string CodigoTicket { get; set; } = string.Empty;
    public string Titulo { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
    public CategoriaSolicitud Categoria { get; set; }
    public PrioridadSolicitud Prioridad { get; set; }
    public EstadoSolicitud Estado { get; set; }
    public DateTime FechaCreacion { get; set; }
    public DateTime? FechaActualizacion { get; set; }

    public int SolicitanteId { get; set; }
    public string SolicitanteNombre { get; set; } = string.Empty;
    public string SolicitanteCorreo { get; set; } = string.Empty;

    public int? AsignadoAId { get; set; }
    public string? AsignadoANombre { get; set; }

    public int? RecursoId { get; set; }
    public string? RecursoCodigo { get; set; }
    public string? RecursoNombre { get; set; }

    public int TotalComentarios { get; set; }
    public int TotalEvidencias { get; set; }
}
