using Microsoft.AspNetCore.SignalR;
using SignalRChatServer.Hubs;
using SignalRChatServer.Models;
using SignalRChatServer.Services;

var builder = WebApplication.CreateBuilder(args);

// Adicionar serviços
builder.Services.AddSignalR(options =>
{
    options.EnableDetailedErrors = true;
    options.MaximumReceiveMessageSize = 1024 * 1024; // 1MB
    options.ClientTimeoutInterval = TimeSpan.FromSeconds(30);
    options.KeepAliveInterval = TimeSpan.FromSeconds(15);
});

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins("http://localhost:3000", "http://localhost:8080")
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

builder.Services.AddSingleton<ChatService>();
builder.Services.AddSingleton<UserService>();

// Configurar logging
builder.Logging.AddConsole();
builder.Logging.AddDebug();

var app = builder.Build();

// Configurar pipeline HTTP
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}

app.UseCors();
app.UseRouting();

// Mapear hubs
app.MapHub<ChatHub>("/chatHub");
app.MapHub<NotificationHub>("/notificationHub");

// Endpoints de status e saúde
app.MapGet("/api/status", () => new { 
    status = "online", 
    timestamp = DateTime.UtcNow,
    version = "1.0.0",
    framework = "NET 9.0"
});

app.MapGet("/api/health", () => new { 
    status = "healthy",
    uptime = Environment.TickCount64,
    memory = GC.GetTotalMemory(false)
});

// Endpoint de negociação manual para SignalR
app.MapPost("/chatHub/negotiate", async (HttpContext context) =>
{
    var connectionId = Guid.NewGuid().ToString();
    var connectionToken = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(connectionId));
    
    var response = new
    {
        connectionId = connectionId,
        connectionToken = connectionToken,
        availableTransports = new[]
        {
            new
            {
                transport = "WebSockets",
                transferFormats = new[] { "Text", "Binary" }
            },
            new
            {
                transport = "ServerSentEvents",
                transferFormats = new[] { "Text" }
            },
            new
            {
                transport = "LongPolling",
                transferFormats = new[] { "Text", "Binary" }
            }
        }
    };
    
    context.Response.ContentType = "application/json";
    await context.Response.WriteAsync(System.Text.Json.JsonSerializer.Serialize(response));
});

Console.WriteLine("🚀 Chat Server iniciado em: http://localhost:5000");
Console.WriteLine("📡 SignalR Hubs disponíveis:");
Console.WriteLine("   - /chatHub");
Console.WriteLine("   - /notificationHub");
Console.WriteLine("🔧 Framework: .NET 9.0");

app.Run();
