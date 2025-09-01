using Microsoft.AspNetCore.SignalR;
using SignalRChatServer.Services;

namespace SignalRChatServer.Hubs;

public class NotificationHub : Hub
{
    private readonly UserService _userService;
    private readonly ILogger<NotificationHub> _logger;

    public NotificationHub(UserService userService, ILogger<NotificationHub> logger)
    {
        _userService = userService;
        _logger = logger;
    }

    public override async Task OnConnectedAsync()
    {
        _logger.LogInformation($"Cliente conectado ao NotificationHub: {Context.ConnectionId}");
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        _logger.LogInformation($"Cliente desconectado do NotificationHub: {Context.ConnectionId}");
        await base.OnDisconnectedAsync(exception);
    }

    public async Task SubscribeToNotifications(string userId)
    {
        var user = _userService.GetUser(userId);
        if (user == null)
        {
            await Clients.Caller.SendAsync("Error", "Usuário não encontrado");
            return;
        }

        await Groups.AddToGroupAsync(Context.ConnectionId, $"notifications_{userId}");
        _logger.LogInformation($"Usuário {user.Name} inscrito para notificações");
    }

    public async Task UnsubscribeFromNotifications(string userId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"notifications_{userId}");
        _logger.LogInformation($"Usuário {userId} cancelou inscrição de notificações");
    }

    public async Task SendNotification(string userId, string title, string message, string type = "info")
    {
        var notification = new
        {
            Id = Guid.NewGuid().ToString(),
            Title = title,
            Message = message,
            Type = type,
            Timestamp = DateTime.UtcNow,
            Read = false
        };

        await Clients.Group($"notifications_{userId}").SendAsync("NotificationReceived", notification);
        _logger.LogInformation($"Notificação enviada para {userId}: {title}");
    }

    public async Task SendGlobalNotification(string title, string message, string type = "info")
    {
        var notification = new
        {
            Id = Guid.NewGuid().ToString(),
            Title = title,
            Message = message,
            Type = type,
            Timestamp = DateTime.UtcNow,
            Read = false,
            Global = true
        };

        await Clients.All.SendAsync("GlobalNotificationReceived", notification);
        _logger.LogInformation($"Notificação global enviada: {title}");
    }

    public async Task MarkNotificationAsRead(string notificationId, string userId)
    {
        await Clients.Group($"notifications_{userId}").SendAsync("NotificationRead", notificationId);
        _logger.LogInformation($"Notificação {notificationId} marcada como lida por {userId}");
    }

    public async Task SendTypingIndicator(string roomId, string userId, bool isTyping)
    {
        var user = _userService.GetUser(userId);
        if (user != null)
        {
            var indicator = new
            {
                RoomId = roomId,
                UserId = userId,
                UserName = user.Name,
                IsTyping = isTyping,
                Timestamp = DateTime.UtcNow
            };

            await Clients.Group($"room_{roomId}").SendAsync("TypingIndicator", indicator);
        }
    }

    public async Task SendUserPresence(string userId, string status)
    {
        var user = _userService.GetUser(userId);
        if (user != null)
        {
            var presence = new
            {
                UserId = userId,
                UserName = user.Name,
                Status = status,
                LastSeen = user.LastSeen,
                Timestamp = DateTime.UtcNow
            };

            await Clients.All.SendAsync("UserPresenceChanged", presence);
        }
    }

    public async Task SendMessageStatus(string messageId, string status, string userId)
    {
        var statusUpdate = new
        {
            MessageId = messageId,
            Status = status,
            UserId = userId,
            Timestamp = DateTime.UtcNow
        };

        await Clients.All.SendAsync("MessageStatusChanged", statusUpdate);
    }

    public async Task SendReactionUpdate(string messageId, string reaction, string userId, bool added)
    {
        var reactionUpdate = new
        {
            MessageId = messageId,
            Reaction = reaction,
            UserId = userId,
            Added = added,
            Timestamp = DateTime.UtcNow
        };

        await Clients.All.SendAsync("ReactionUpdated", reactionUpdate);
    }

    public async Task SendRoomUpdate(string roomId, string action, object data)
    {
        var roomUpdate = new
        {
            RoomId = roomId,
            Action = action,
            Data = data,
            Timestamp = DateTime.UtcNow
        };

        await Clients.All.SendAsync("RoomUpdated", roomUpdate);
    }

    public async Task SendSystemAlert(string message, string level = "info")
    {
        var alert = new
        {
            Id = Guid.NewGuid().ToString(),
            Message = message,
            Level = level,
            Timestamp = DateTime.UtcNow
        };

        await Clients.All.SendAsync("SystemAlert", alert);
        _logger.LogInformation($"Alerta do sistema: {message}");
    }

    public async Task SendPerformanceMetrics(string userId, object metrics)
    {
        await Clients.Group($"metrics_{userId}").SendAsync("PerformanceMetrics", metrics);
    }

    public async Task SubscribeToMetrics(string userId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"metrics_{userId}");
    }

    public async Task UnsubscribeFromMetrics(string userId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"metrics_{userId}");
    }
}
