using Microsoft.EntityFrameworkCore;
using CampusConnect.Web.Models.Entities;
using CampusConnect.Web.Models.Enums;

namespace CampusConnect.Web.Data;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<Usuario> Usuarios => Set<Usuario>();
    public DbSet<Recurso> Recursos => Set<Recurso>();
    public DbSet<Solicitud> Solicitudes => Set<Solicitud>();
    public DbSet<Evidencia> Evidencias => Set<Evidencia>();
    public DbSet<Comentario> Comentarios => Set<Comentario>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Índices únicos
        modelBuilder.Entity<Usuario>()
            .HasIndex(u => u.Correo)
            .IsUnique();

        modelBuilder.Entity<Recurso>()
            .HasIndex(r => r.Codigo)
            .IsUnique();

        modelBuilder.Entity<Solicitud>()
            .HasIndex(s => s.CodigoTicket)
            .IsUnique();

        // Relaciones de Solicitud con Usuario (Solicitante y Asignado)
        modelBuilder.Entity<Solicitud>()
            .HasOne(s => s.Solicitante)
            .WithMany(u => u.SolicitudesCreadas)
            .HasForeignKey(s => s.SolicitanteId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Solicitud>()
            .HasOne(s => s.AsignadoA)
            .WithMany(u => u.SolicitudesAsignadas)
            .HasForeignKey(s => s.AsignadoAId)
            .OnDelete(DeleteBehavior.Restrict);

        // Relación de Solicitud con Recurso
        modelBuilder.Entity<Solicitud>()
            .HasOne(s => s.Recurso)
            .WithMany(r => r.Solicitudes)
            .HasForeignKey(s => s.RecursoId)
            .OnDelete(DeleteBehavior.SetNull);

        // Relaciones en Cascada para Evidencias y Comentarios de una Solicitud
        modelBuilder.Entity<Solicitud>()
            .HasMany(s => s.Evidencias)
            .WithOne(e => e.Solicitud)
            .HasForeignKey(e => e.SolicitudId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Solicitud>()
            .HasMany(s => s.Comentarios)
            .WithOne(c => c.Solicitud)
            .HasForeignKey(c => c.SolicitudId)
            .OnDelete(DeleteBehavior.Cascade);

        // Restricción para autores de evidencia y comentario (evitar borrar usuario y borrar historial)
        modelBuilder.Entity<Evidencia>()
            .HasOne(e => e.SubidoPor)
            .WithMany(u => u.Evidencias)
            .HasForeignKey(e => e.SubidoPorId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Comentario>()
            .HasOne(c => c.Usuario)
            .WithMany(u => u.Comentarios)
            .HasForeignKey(c => c.UsuarioId)
            .OnDelete(DeleteBehavior.Restrict);

        // Datos semilla iniciales (Seed Data)
        SeedInitialData(modelBuilder);
    }

    private static void SeedInitialData(ModelBuilder modelBuilder)
    {
        var fechaBase = new DateTime(2026, 1, 15, 8, 0, 0, DateTimeKind.Utc);

        modelBuilder.Entity<Usuario>().HasData(
            new Usuario
            {
                Id = 1,
                NombreCompleto = "Juan Pérez (Estudiante)",
                Correo = "juan.perez@universidad.edu",
                PasswordHash = "hashed_secret_password_123",
                Rol = RolUsuario.Estudiante,
                CarreraODepartamento = "Ingeniería de Sistemas",
                Telefono = "555-0101",
                FechaRegistro = fechaBase,
                Activo = true
            },
            new Usuario
            {
                Id = 2,
                NombreCompleto = "Dra. María Gómez (Administradora)",
                Correo = "maria.gomez@universidad.edu",
                PasswordHash = "hashed_secret_admin_123",
                Rol = RolUsuario.Administrativo,
                CarreraODepartamento = "Dirección de Infraestructura y Servicios",
                Telefono = "555-0202",
                FechaRegistro = fechaBase,
                Activo = true
            },
            new Usuario
            {
                Id = 3,
                NombreCompleto = "Ing. Carlos Rivas (Soporte TI)",
                Correo = "carlos.rivas@universidad.edu",
                PasswordHash = "hashed_secret_tech_123",
                Rol = RolUsuario.TecnicoSoporte,
                CarreraODepartamento = "Centro de Tecnologías de Información",
                Telefono = "555-0303",
                FechaRegistro = fechaBase,
                Activo = true
            }
        );

        modelBuilder.Entity<Recurso>().HasData(
            new Recurso
            {
                Id = 1,
                Codigo = "LAB-SIS-05",
                Nombre = "Equipo de Cómputo Dell Core i7",
                Tipo = TipoRecurso.Equipamiento,
                Ubicacion = "Edificio A - Laboratorio de Sistemas 1",
                Descripcion = "PC de desarrollo para asignaturas de desarrollo y bases de datos",
                Estado = EstadoRecurso.Disponible,
                FechaRegistro = fechaBase
            },
            new Recurso
            {
                Id = 2,
                Codigo = "AUD-PROY-01",
                Nombre = "Proyector Láser Epson 4K",
                Tipo = TipoRecurso.Equipamiento,
                Ubicacion = "Edificio Central - Auditorio Mayor",
                Descripcion = "Sistema de proyección para conferencias y ponencias",
                Estado = EstadoRecurso.Disponible,
                FechaRegistro = fechaBase
            },
            new Recurso
            {
                Id = 3,
                Codigo = "AULA-204-CLIMA",
                Nombre = "Unidad Central de Aire Acondicionado",
                Tipo = TipoRecurso.Infraestructura,
                Ubicacion = "Edificio B - Aula Magna 204",
                Descripcion = "Climatización de 24,000 BTU",
                Estado = EstadoRecurso.Disponible,
                FechaRegistro = fechaBase
            }
        );
    }
}
