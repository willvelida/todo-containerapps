using Microsoft.AspNetCore.Mvc;

namespace Todo.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class TodoController : ControllerBase
    {
        private readonly ILogger<TodoController> _logger;

        public TodoController(ILogger<TodoController> logger)
        {
            _logger=logger;
        }

        [HttpGet(Name = "GetTodoItem")]
        public ActionResult<Todo> Get()
        {
            var todo = new Todo()
            {
                Id = Guid.NewGuid().ToString(),
                Name = "Sample Todo",
                IsDone = false,
            };

            return new OkObjectResult(todo);
        }
    }
}
