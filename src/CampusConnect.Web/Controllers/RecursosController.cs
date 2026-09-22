using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CampusConnect.Web.Data;
using CampusConnect.Web.Models.Entities;
using CampusConnect.Web.Models.Enums;
using CampusConnect.Web.Models.ViewModels;

namespace CampusConnect.Web.Controllers;

public class RecursosController : Controller
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<RecursosController> _logger;

    public RecursosController(ApplicationDbContext context, ILogger<RecursosController> logger)
    {
        _context = context;
        _logger = logger;
    }

    // GET: /Recursos
    public async Task<IActionResult> Index(string? busqueda, TipoRecurso? tipo, EstadoRecurso? estado)
    {
        var query = _context.Recursos.AsNoTracking();

        var total = await query.CountAsync();
        var disponibles = await query.CountAsync(r => r.Estado == EstadoRecurso.Disponible);
        var enMantenimiento = await query.CountAsync(r => r.Estado == EstadoRecurso.EnMantenimiento);
        var fueraServicio = await query.CountAsync(r => r.Estado == EstadoRecurso.FueraDeServicio);

        if (!string.IsNullOrWhiteSpace(busqueda))
        {
            var b = busqueda.Trim().ToLower();
            query = query.Where(r => 
                r.Codigo.ToLower().Contains(b) || 
                r.Nombre.ToLower().Contains(b) || 
                r.Ubicacion.ToLower().Contains(b));
        }

        if (tipo.HasValue)
            query = query.Where(r => r.Tipo == tipo.Value);

        if (estado.HasValue)
            query = query.Where(r => r.Estado == estado.Value);

        var list = await query
            .OrderBy(r => r.Tipo)
            .ThenBy(r => r.Nombre)
            .ToListAsync();

        var viewModel = new RecursoIndexViewModel
        {
            Recursos = list,
            TotalRecursos = total,
            TotalDisponibles = disponibles,
            TotalEnMantenimiento = enMantenimiento,
            TotalFueraDeServicio = fueraServicio,
            Busqueda = busqueda,
            TipoFiltro = tipo,
            EstadoFiltro = estado
        };

        return View(viewModel);
    }

    // GET: /Recursos/Create
    public IActionResult Create()
    {
        var model = new RecursoFormViewModel
        {
            Estado = EstadoRecurso.Disponible,
            Tipo = TipoRecurso.Equipamiento
        };
        return View(model);
    }

    // POST: /Recursos/Create
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(RecursoFormViewModel model)
    {
        if (!ModelState.IsValid)
            return View(model);

        // Validar código único
        var existeCodigo = await _context.Recursos.AnyAsync(r => r.Codigo.ToLower() == model.Codigo.Trim().ToLower());
        if (existeCodigo)
        {
            ModelState.AddModelError(nameof(model.Codigo), $"Ya existe un recurso registrado con el código '{model.Codigo}'.");
            return View(model);
        }

        var recurso = new Recurso
        {
            Codigo = model.Codigo.Trim().ToUpperInvariant(),
            Nombre = model.Nombre.Trim(),
            Tipo = model.Tipo,
            Ubicacion = model.Ubicacion.Trim(),
            Descripcion = model.Descripcion?.Trim(),
            Estado = model.Estado,
            FechaRegistro = DateTime.UtcNow
        };

        _context.Recursos.Add(recurso);
        await _context.SaveChangesAsync();

        TempData["SuccessMessage"] = $"Recurso '{recurso.Codigo} - {recurso.Nombre}' registrado exitosamente.";
        return RedirectToAction(nameof(Index));
    }

    // GET: /Recursos/Edit/5
    public async Task<IActionResult> Edit(int id)
    {
        var recurso = await _context.Recursos.FindAsync(id);
        if (recurso == null)
        {
            TempData["ErrorMessage"] = "El recurso no existe.";
            return RedirectToAction(nameof(Index));
        }

        var model = new RecursoFormViewModel
        {
            Id = recurso.Id,
            Codigo = recurso.Codigo,
            Nombre = recurso.Nombre,
            Tipo = recurso.Tipo,
            Ubicacion = recurso.Ubicacion,
            Descripcion = recurso.Descripcion,
            Estado = recurso.Estado
        };

        return View(model);
    }

    // POST: /Recursos/Edit/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(int id, RecursoFormViewModel model)
    {
        if (id != model.Id)
            return BadRequest();

        if (!ModelState.IsValid)
            return View(model);

        var recurso = await _context.Recursos.FindAsync(id);
        if (recurso == null)
        {
            TempData["ErrorMessage"] = "El recurso a editar ya no existe.";
            return RedirectToAction(nameof(Index));
        }

        var existeCodigo = await _context.Recursos.AnyAsync(r => r.Id != id && r.Codigo.ToLower() == model.Codigo.Trim().ToLower());
        if (existeCodigo)
        {
            ModelState.AddModelError(nameof(model.Codigo), $"Ya existe otro recurso con el código '{model.Codigo}'.");
            return View(model);
        }

        recurso.Codigo = model.Codigo.Trim().ToUpperInvariant();
        recurso.Nombre = model.Nombre.Trim();
        recurso.Tipo = model.Tipo;
        recurso.Ubicacion = model.Ubicacion.Trim();
        recurso.Descripcion = model.Descripcion?.Trim();
        recurso.Estado = model.Estado;

        await _context.SaveChangesAsync();

        TempData["SuccessMessage"] = $"Recurso '{recurso.Codigo}' actualizado con éxito.";
        return RedirectToAction(nameof(Index));
    }

    // GET: /Recursos/Details/5
    public async Task<IActionResult> Details(int id)
    {
        var recurso = await _context.Recursos.FirstOrDefaultAsync(r => r.Id == id);
        if (recurso == null)
        {
            TempData["ErrorMessage"] = "El recurso solicitado no fue encontrado.";
            return RedirectToAction(nameof(Index));
        }

        var solicitudesRelacionadas = await _context.Solicitudes
            .Include(s => s.Solicitante)
            .Include(s => s.AsignadoA)
            .Where(s => s.RecursoId == id)
            .OrderByDescending(s => s.FechaCreacion)
            .ToListAsync();

        var model = new RecursoDetailsViewModel
        {
            Recurso = recurso,
            SolicitudesRelacionadas = solicitudesRelacionadas
        };

        return View(model);
    }

    // POST: /Recursos/Delete/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Delete(int id)
    {
        var recurso = await _context.Recursos.FindAsync(id);
        if (recurso == null)
        {
            TempData["ErrorMessage"] = "El recurso no existe.";
            return RedirectToAction(nameof(Index));
        }

        // Verificar si tiene solicitudes asociadas
        var tieneSolicitudes = await _context.Solicitudes.AnyAsync(s => s.RecursoId == id);
        if (tieneSolicitudes)
        {
            // En vez de eliminar físicamente, marcamos como FueraDeServicio para mantener integridad histórica
            recurso.Estado = EstadoRecurso.FueraDeServicio;
            await _context.SaveChangesAsync();
            TempData["WarningMessage"] = $"El recurso '{recurso.Codigo}' tiene solicitudes históricas asociadas. Se ha marcado como 'Fuera de Servicio' para preservar la integridad de datos.";
            return RedirectToAction(nameof(Index));
        }

        _context.Recursos.Remove(recurso);
        await _context.SaveChangesAsync();

        TempData["SuccessMessage"] = $"Recurso '{recurso.Codigo}' eliminado correctamente.";
        return RedirectToAction(nameof(Index));
    }
}
