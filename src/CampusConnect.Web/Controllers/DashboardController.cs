using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using CampusConnect.Web.Data;
using CampusConnect.Web.Models.Entities;
using CampusConnect.Web.Models.Enums;
using CampusConnect.Web.Models.ViewModels;

namespace CampusConnect.Web.Controllers;

public class DashboardController : Controller
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<DashboardController> _logger;

    public DashboardController(ApplicationDbContext context, ILogger<DashboardController> logger)
    {
        _context = context;
        _logger = logger;
    }

    // GET: /Dashboard
    public async Task<IActionResult> Index(
        string? busqueda,
        EstadoSolicitud? estado,
        PrioridadSolicitud? prioridad,
        CategoriaSolicitud? categoria)
    {
        var todasQuery = _context.Solicitudes
            .Include(s => s.Solicitante)
            .Include(s => s.AsignadoA)
            .Include(s => s.Recurso)
            .Include(s => s.Comentarios)
            .Include(s => s.Evidencias)
            .AsNoTracking();

        // Cálculo global de KPIs
        var total = await todasQuery.CountAsync();
        var pendientes = await todasQuery.CountAsync(s => s.Estado == EstadoSolicitud.Pendiente);
        var enProceso = await todasQuery.CountAsync(s => s.Estado == EstadoSolicitud.EnProceso);
        var atendidas = await todasQuery.CountAsync(s => s.Estado == EstadoSolicitud.Atendida);
        var urgentesSinAtender = await todasQuery.CountAsync(s => 
            s.Prioridad == PrioridadSolicitud.Urgente && 
            (s.Estado == EstadoSolicitud.Pendiente || s.Estado == EstadoSolicitud.EnProceso));

        // Aplicar filtros
        var filtradasQuery = todasQuery.AsQueryable();

        if (!string.IsNullOrWhiteSpace(busqueda))
        {
            var b = busqueda.Trim().ToLower();
            filtradasQuery = filtradasQuery.Where(s =>
                s.CodigoTicket.ToLower().Contains(b) ||
                s.Titulo.ToLower().Contains(b) ||
                s.Descripcion.ToLower().Contains(b) ||
                (s.Solicitante != null && s.Solicitante.NombreCompleto.ToLower().Contains(b)));
        }

        if (estado.HasValue)
            filtradasQuery = filtradasQuery.Where(s => s.Estado == estado.Value);

        if (prioridad.HasValue)
            filtradasQuery = filtradasQuery.Where(s => s.Prioridad == prioridad.Value);

        if (categoria.HasValue)
            filtradasQuery = filtradasQuery.Where(s => s.Categoria == categoria.Value);

        // Orden de priorización administrativa: Urgente -> Alta -> Media -> Baja y luego fecha
        var listaSolicitudes = await filtradasQuery
            .OrderByDescending(s => s.Prioridad)
            .ThenByDescending(s => s.FechaCreacion)
            .Select(s => new SolicitudDashboardItem
            {
                Id = s.Id,
                CodigoTicket = s.CodigoTicket,
                Titulo = s.Titulo,
                Descripcion = s.Descripcion,
                Categoria = s.Categoria,
                Prioridad = s.Prioridad,
                Estado = s.Estado,
                FechaCreacion = s.FechaCreacion,
                FechaActualizacion = s.FechaActualizacion,
                SolicitanteId = s.SolicitanteId,
                SolicitanteNombre = s.Solicitante != null ? s.Solicitante.NombreCompleto : "Sin Solicitante",
                SolicitanteCorreo = s.Solicitante != null ? s.Solicitante.Correo : "",
                AsignadoAId = s.AsignadoAId,
                AsignadoANombre = s.AsignadoA != null ? s.AsignadoA.NombreCompleto : null,
                RecursoId = s.RecursoId,
                RecursoCodigo = s.Recurso != null ? s.Recurso.Codigo : null,
                RecursoNombre = s.Recurso != null ? s.Recurso.Nombre : null,
                TotalComentarios = s.Comentarios.Count,
                TotalEvidencias = s.Evidencias.Count
            })
            .ToListAsync();

        // Obtener personal técnico o administrativo para dropdown de asignación
        var tecnicos = await _context.Usuarios
            .Where(u => u.Activo && (u.Rol == RolUsuario.TecnicoSoporte || u.Rol == RolUsuario.Administrativo))
            .OrderBy(u => u.NombreCompleto)
            .Select(u => new SelectListItem
            {
                Value = u.Id.ToString(),
                Text = $"{u.NombreCompleto} ({u.Rol})"
            })
            .ToListAsync();

        var viewModel = new DashboardViewModel
        {
            TotalSolicitudes = total,
            PendientesCount = pendientes,
            EnProcesoCount = enProceso,
            AtendidasCount = atendidas,
            UrgentesSinAtenderCount = urgentesSinAtender,
            Busqueda = busqueda,
            EstadoFiltro = estado,
            PrioridadFiltro = prioridad,
            CategoriaFiltro = categoria,
            Solicitudes = listaSolicitudes,
            PersonalSoporteList = tecnicos
        };

        return View(viewModel);
    }

    // POST: /Dashboard/AsignarResponsable
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> AsignarResponsable(int solicitudId, int responsableId)
    {
        var solicitud = await _context.Solicitudes.FindAsync(solicitudId);
        if (solicitud == null)
        {
            TempData["ErrorMessage"] = "No se encontró la solicitud especificada.";
            return RedirectToAction(nameof(Index));
        }

        var responsable = await _context.Usuarios.FindAsync(responsableId);
        if (responsable == null)
        {
            TempData["ErrorMessage"] = "El usuario seleccionado no es válido.";
            return RedirectToAction(nameof(Index));
        }

        solicitud.AsignadoAId = responsableId;
        if (solicitud.Estado == EstadoSolicitud.Pendiente)
        {
            solicitud.Estado = EstadoSolicitud.EnProceso;
        }
        solicitud.FechaActualizacion = DateTime.UtcNow;

        // Comentario automático de trazabilidad
        var comentario = new Comentario
        {
            SolicitudId = solicitudId,
            UsuarioId = responsableId,
            Mensaje = $"Requerimiento asignado a {responsable.NombreCompleto} para su seguimiento y atención.",
            EsInterno = false,
            FechaCreacion = DateTime.UtcNow
        };
        _context.Comentarios.Add(comentario);

        await _context.SaveChangesAsync();

        TempData["SuccessMessage"] = $"Se asignó correctamente a {responsable.NombreCompleto} al ticket {solicitud.CodigoTicket}.";
        return RedirectToAction(nameof(Index));
    }

    // POST: /Dashboard/CambiarEstado
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> CambiarEstado(int solicitudId, EstadoSolicitud nuevoEstado, string? nota)
    {
        var solicitud = await _context.Solicitudes.FindAsync(solicitudId);
        if (solicitud == null)
        {
            TempData["ErrorMessage"] = "No se encontró la solicitud especificada.";
            return RedirectToAction(nameof(Index));
        }

        var estadoAnterior = solicitud.Estado;
        solicitud.Estado = nuevoEstado;
        solicitud.FechaActualizacion = DateTime.UtcNow;

        if (nuevoEstado == EstadoSolicitud.Atendida || nuevoEstado == EstadoSolicitud.Cancelada || nuevoEstado == EstadoSolicitud.Rechazada)
        {
            solicitud.FechaCierre = DateTime.UtcNow;
        }

        if (!string.IsNullOrWhiteSpace(nota))
        {
            // Registrar comentario con el usuario asignado o administrativo base (ID 2 de seed data)
            var autorId = solicitud.AsignadoAId ?? 2;
            var notaLimpia = nota.Trim();
            var mensaje = estadoAnterior != nuevoEstado
                ? $"Cambio de estado: de {estadoAnterior} a {nuevoEstado}. Nota: {notaLimpia}"
                : $"Nota: {notaLimpia}";
            var comentario = new Comentario
            {
                SolicitudId = solicitudId,
                UsuarioId = autorId,
                Mensaje = mensaje,
                EsInterno = false,
                FechaCreacion = DateTime.UtcNow
            };
            _context.Comentarios.Add(comentario);
        }

        await _context.SaveChangesAsync();

        TempData["SuccessMessage"] = $"Estado del ticket {solicitud.CodigoTicket} actualizado a '{nuevoEstado}'.";
        return RedirectToAction(nameof(Index));
    }

    // GET: /Dashboard/Detalle/5
    public async Task<IActionResult> Detalle(int id)
    {
        var solicitud = await _context.Solicitudes
            .Include(s => s.Solicitante)
            .Include(s => s.AsignadoA)
            .Include(s => s.Recurso)
            .Include(s => s.Comentarios)
                .ThenInclude(c => c.Usuario)
            .Include(s => s.Evidencias)
                .ThenInclude(e => e.SubidoPor)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (solicitud == null)
        {
            TempData["ErrorMessage"] = "La solicitud solicitada no existe.";
            return RedirectToAction(nameof(Index));
        }

        ViewBag.PersonalSoporte = await _context.Usuarios
            .Where(u => u.Activo && (u.Rol == RolUsuario.TecnicoSoporte || u.Rol == RolUsuario.Administrativo))
            .OrderBy(u => u.NombreCompleto)
            .Select(u => new SelectListItem
            {
                Value = u.Id.ToString(),
                Text = $"{u.NombreCompleto} ({u.Rol})"
            })
            .ToListAsync();

        return View(solicitud);
    }
}
