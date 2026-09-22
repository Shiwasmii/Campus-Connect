using CampusConnect.Web.Models.Enums;

namespace CampusConnect.Web.Models.ViewModels;

public class ReportesViewModel
{
    // Métricas generales
    public int TotalSolicitudes { get; set; }
    public int PendientesCount { get; set; }
    public int EnProcesoCount { get; set; }
    public int AtendidasCount { get; set; }
    public int CanceladasRechazadasCount { get; set; }

    public double TasaResolucionPorcentaje { get; set; }
    public double TiempoPromedioAtencionHoras { get; set; }

    // Distribución por Categoría
    public List<CategoriaReporteItem> PorCategoria { get; set; } = new();

    // Distribución por Prioridad
    public List<PrioridadReporteItem> PorPrioridad { get; set; } = new();

    // Desglose por Responsable Técnico / Administrativo
    public List<ResponsableReporteItem> PorResponsable { get; set; } = new();
}

public class CategoriaReporteItem
{
    public CategoriaSolicitud Categoria { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public int Cantidad { get; set; }
    public double Porcentaje { get; set; }
}

public class PrioridadReporteItem
{
    public PrioridadSolicitud Prioridad { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public int Cantidad { get; set; }
    public double Porcentaje { get; set; }
}

public class ResponsableReporteItem
{
    public int UsuarioId { get; set; }
    public string NombreCompleto { get; set; } = string.Empty;
    public string Rol { get; set; } = string.Empty;
    public int TotalAsignadas { get; set; }
    public int Atendidas { get; set; }
    public int PendientesOEnProceso { get; set; }
    public double EficienciaPorcentaje { get; set; }
}
