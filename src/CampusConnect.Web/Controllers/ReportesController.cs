using System.Text;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CampusConnect.Web.Data;
using CampusConnect.Web.Models.Enums;
using CampusConnect.Web.Models.ViewModels;

namespace CampusConnect.Web.Controllers;

public class ReportesController : Controller
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<ReportesController> _logger;

    public ReportesController(ApplicationDbContext context, ILogger<ReportesController> logger)
    {
        _context = context;
        _logger = logger;
    }

    // GET: /Reportes
    public async Task<IActionResult> Index()
    {
        var solicitudes = await _context.Solicitudes
            .Include(s => s.AsignadoA)
            .AsNoTracking()
            .ToListAsync();

        var total = solicitudes.Count;
        var pendientes = solicitudes.Count(s => s.Estado == EstadoSolicitud.Pendiente);
        var enProceso = solicitudes.Count(s => s.Estado == EstadoSolicitud.EnProceso);
        var atendidas = solicitudes.Count(s => s.Estado == EstadoSolicitud.Atendida);
        var canceladasRechazadas = solicitudes.Count(s => s.Estado == EstadoSolicitud.Cancelada || s.Estado == EstadoSolicitud.Rechazada);

        // Cálculo de tasa de resolución
        var tasaResolucion = total > 0 ? Math.Round((double)atendidas / total * 100, 1) : 0;

        // Cálculo de tiempo promedio de atención (en horas)
        var solicitudesConCierre = solicitudes
            .Where(s => s.Estado == EstadoSolicitud.Atendida && s.FechaCierre.HasValue)
            .ToList();

        double tiempoPromedioHoras = 0;
        if (solicitudesConCierre.Any())
        {
            tiempoPromedioHoras = Math.Round(
                solicitudesConCierre.Average(s => (s.FechaCierre!.Value - s.FechaCreacion).TotalHours), 1);
        }

        // Distribución por Categoría
        var categorias = Enum.GetValues<CategoriaSolicitud>();
        var porCategoria = categorias.Select(c =>
        {
            var count = solicitudes.Count(s => s.Categoria == c);
            var pct = total > 0 ? Math.Round((double)count / total * 100, 1) : 0;
            return new CategoriaReporteItem
            {
                Categoria = c,
                Nombre = c switch
                {
                    CategoriaSolicitud.Mantenimiento => "Mantenimiento",
                    CategoriaSolicitud.SoporteTecnologico => "Soporte Tecnológico",
                    CategoriaSolicitud.Infraestructura => "Infraestructura",
                    _ => c.ToString()
                },
                Cantidad = count,
                Porcentaje = pct
            };
        }).ToList();

        // Distribución por Prioridad
        var prioridades = Enum.GetValues<PrioridadSolicitud>();
        var porPrioridad = prioridades.Select(p =>
        {
            var count = solicitudes.Count(s => s.Prioridad == p);
            var pct = total > 0 ? Math.Round((double)count / total * 100, 1) : 0;
            return new PrioridadReporteItem
            {
                Prioridad = p,
                Nombre = p.ToString(),
                Cantidad = count,
                Porcentaje = pct
            };
        }).ToList();

        // Desglose por Responsables técnicos
        var tecnicos = await _context.Usuarios
            .Where(u => u.Rol == RolUsuario.TecnicoSoporte || u.Rol == RolUsuario.Administrativo)
            .AsNoTracking()
            .ToListAsync();

        var porResponsable = tecnicos.Select(t =>
        {
            var asignadas = solicitudes.Count(s => s.AsignadoAId == t.Id);
            var resueltas = solicitudes.Count(s => s.AsignadoAId == t.Id && s.Estado == EstadoSolicitud.Atendida);
            var pendientesOP = solicitudes.Count(s => s.AsignadoAId == t.Id && (s.Estado == EstadoSolicitud.Pendiente || s.Estado == EstadoSolicitud.EnProceso));
            var ef = asignadas > 0 ? Math.Round((double)resueltas / asignadas * 100, 1) : 0;

            return new ResponsableReporteItem
            {
                UsuarioId = t.Id,
                NombreCompleto = t.NombreCompleto,
                Rol = t.Rol.ToString(),
                TotalAsignadas = asignadas,
                Atendidas = resueltas,
                PendientesOEnProceso = pendientesOP,
                EficienciaPorcentaje = ef
            };
        }).OrderByDescending(r => r.TotalAsignadas).ToList();

        var model = new ReportesViewModel
        {
            TotalSolicitudes = total,
            PendientesCount = pendientes,
            EnProcesoCount = enProceso,
            AtendidasCount = atendidas,
            CanceladasRechazadasCount = canceladasRechazadas,
            TasaResolucionPorcentaje = tasaResolucion,
            TiempoPromedioAtencionHoras = tiempoPromedioHoras,
            PorCategoria = porCategoria,
            PorPrioridad = porPrioridad,
            PorResponsable = porResponsable
        };

        return View(model);
    }

    // GET: /Reportes/ExportarCsv
    public async Task<IActionResult> ExportarCsv()
    {
        var solicitudes = await _context.Solicitudes
            .Include(s => s.Solicitante)
            .Include(s => s.AsignadoA)
            .Include(s => s.Recurso)
            .OrderByDescending(s => s.FechaCreacion)
            .AsNoTracking()
            .ToListAsync();

        var sb = new StringBuilder();
        sb.AppendLine("CodigoTicket,Titulo,Categoria,Prioridad,Estado,FechaCreacion,FechaCierre,Solicitante,AsignadoA,Recurso");

        foreach (var s in solicitudes)
        {
            var titulo = $"\"{s.Titulo.Replace("\"", "\"\"")}\"";
            var solicitante = s.Solicitante != null ? $"\"{s.Solicitante.NombreCompleto}\"" : "\"\"";
            var asignado = s.AsignadoA != null ? $"\"{s.AsignadoA.NombreCompleto}\"" : "\"\"";
            var recurso = s.Recurso != null ? $"\"{s.Recurso.Codigo} - {s.Recurso.Nombre}\"" : "\"\"";
            var fechaCierre = s.FechaCierre.HasValue ? s.FechaCierre.Value.ToString("yyyy-MM-dd HH:mm:ss") : "";

            sb.AppendLine($"{s.CodigoTicket},{titulo},{s.Categoria},{s.Prioridad},{s.Estado},{s.FechaCreacion:yyyy-MM-dd HH:mm:ss},{fechaCierre},{solicitante},{asignado},{recurso}");
        }

        var bytes = Encoding.UTF8.GetPreamble().Concat(Encoding.UTF8.GetBytes(sb.ToString())).ToArray();
        var fileName = $"Reporte_CampusConnect_{DateTime.UtcNow:yyyyMMdd_HHmmss}.csv";

        return File(bytes, "text/csv", fileName);
    }
}
