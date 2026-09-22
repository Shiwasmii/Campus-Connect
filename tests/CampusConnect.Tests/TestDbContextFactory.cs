using Microsoft.EntityFrameworkCore;
using CampusConnect.Web.Data;
using CampusConnect.Web.Models.Entities;
using CampusConnect.Web.Models.Enums;

namespace CampusConnect.Tests;

public static class TestDbContextFactory
{
    public static ApplicationDbContext CreateInMemoryDbContext(string? dbName = null)
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase(databaseName: dbName ?? Guid.NewGuid().ToString())
            .Options;

        var context = new ApplicationDbContext(options);

        // Sembrar datos de prueba base
        context.Usuarios.AddRange(
            new Usuario
            {
                Id = 1,
                NombreCompleto = "Estudiante Juan Pérez",
                Correo = "juan.perez@universidad.edu",
                PasswordHash = "password123",
                Rol = RolUsuario.Estudiante,
                Activo = true
            },
            new Usuario
            {
                Id = 2,
                NombreCompleto = "Administradora María Gómez",
                Correo = "maria.gomez@universidad.edu",
                PasswordHash = "admin123",
                Rol = RolUsuario.Administrativo,
                Activo = true
            },
            new Usuario
            {
                Id = 3,
                NombreCompleto = "Técnico Carlos Rivas",
                Correo = "carlos.rivas@universidad.edu",
                PasswordHash = "tech123",
                Rol = RolUsuario.TecnicoSoporte,
                Activo = true
            }
        );

        context.Recursos.AddRange(
            new Recurso
            {
                Id = 1,
                Codigo = "LAB-SIS-01",
                Nombre = "Computadora Laboratorio 1",
                Tipo = TipoRecurso.Equipamiento,
                Ubicacion = "Edificio A - Aula 101",
                Estado = EstadoRecurso.Disponible
            },
            new Recurso
            {
                Id = 2,
                Codigo = "AULA-CLIMA-01",
                Nombre = "Aire Acondicionado Aula 204",
                Tipo = TipoRecurso.Infraestructura,
                Ubicacion = "Edificio B - Aula 204",
                Estado = EstadoRecurso.Disponible
            }
        );

        context.SaveChanges();
        return context;
    }
}
