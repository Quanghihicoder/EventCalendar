using Microsoft.AspNetCore.Mvc;

namespace EventCalendar.Controllers
{
    [ApiController]
    [Route("api")]
    public class ApiController : ControllerBase
    {
        [HttpGet]
        public IActionResult Get()
        {
            return Ok("Hello from .NET API");
        }
    }
}
