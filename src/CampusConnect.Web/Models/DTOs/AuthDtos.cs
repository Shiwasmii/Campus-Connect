using System.ComponentModel.DataAnnotations;

namespace CampusConnect.Web.Models.DTOs;

public class LoginRequestDto
{
    [Required(ErrorMessage = "El correo electrónico es obligatorio.")]
    [EmailAddress(ErrorMessage = "Formato de correo no válido.")]
    public string Correo { get; set; } = string.Empty;

    [Required(ErrorMessage = "La contraseña es obligatoria.")]
    public string Password { get; set; } = string.Empty;
}

public class LoginResponseDto
{
    public bool Exitoso { get; set; }
    public string Mensaje { get; set; } = string.Empty;
    public UsuarioInfo? Usuario { get; set; }
    public string? TokenSimulado { get; set; }
}
