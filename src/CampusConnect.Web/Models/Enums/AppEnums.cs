namespace CampusConnect.Web.Models.Enums;

public enum RolUsuario
{
    Estudiante = 1,
    Administrativo = 2,
    TecnicoSoporte = 3
}

public enum CategoriaSolicitud
{
    Mantenimiento = 1,
    SoporteTecnologico = 2,
    Infraestructura = 3
}

public enum PrioridadSolicitud
{
    Baja = 1,
    Media = 2,
    Alta = 3,
    Urgente = 4
}

public enum EstadoSolicitud
{
    Pendiente = 1,
    EnProceso = 2,
    Atendida = 3,
    Cancelada = 4,
    Rechazada = 5
}

public enum TipoRecurso
{
    Infraestructura = 1,
    Equipamiento = 2
}

public enum EstadoRecurso
{
    Disponible = 1,
    EnUso = 2,
    EnMantenimiento = 3,
    FueraDeServicio = 4
}
