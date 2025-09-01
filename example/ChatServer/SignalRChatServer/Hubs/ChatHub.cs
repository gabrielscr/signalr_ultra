using Microsoft.AspNetCore.SignalR;
using SignalRChatServer.Models;
using SignalRChatServer.Services;

namespace SignalRChatServer.Hubs;

public class ChatHub : Hub
{
    private readonly ChatService _chatService;
    private readonly UserService _userService;
    private readonly ILogger<ChatHub> _logger;

    public ChatHub(ChatService chatService, UserService userService, ILogger<ChatHub> logger)
    {
        _chatService = chatService;
        _userService = userService;
        _logger = logger;
    }

    public override async Task OnConnectedAsync()
    {
        _logger.LogInformation($"Cliente conectado: {Context.ConnectionId}");
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = _userService.GetUserIdByConnection(Context.ConnectionId);
        if (userId != null)
        {
            _userService.RemoveConnection(Context.ConnectionId);
            await NotifyUserStatusChange(userId, UserStatus.Offline);
        }

        _logger.LogInformation($"Cliente desconectado: {Context.ConnectionId}");
        await base.OnDisconnectedAsync(exception);
    }

    public async Task JoinRoom(string roomId, string userId)
    {
        var user = _userService.GetUser(userId);
        if (user == null)
        {
            await Clients.Caller.SendAsync("Error", "Usuário não encontrado");
            return;
        }

        _userService.MapConnectionToUser(Context.ConnectionId, userId);
        _userService.AddUserToRoom(userId, roomId);
        _chatService.JoinRoom(roomId, userId);

        await Groups.AddToGroupAsync(Context.ConnectionId, roomId);

        // Enviar mensagem de sistema
        var systemMessage = new ChatMessage
        {
            Content = $"{user.Name} entrou na sala",
            SenderId = "system",
            SenderName = "Sistema",
            SenderAvatar = "",
            Type = MessageType.System,
            RoomId = roomId
        };

        _chatService.AddMessage(systemMessage);
        await Clients.Group(roomId).SendAsync("MessageReceived", systemMessage);

        // Enviar histórico de mensagens
        var messages = _chatService.GetRoomMessages(roomId);
        await Clients.Caller.SendAsync("MessageHistory", messages);

        // Notificar mudança de status
        await NotifyUserStatusChange(userId, UserStatus.Online);

        _logger.LogInformation($"Usuário {user.Name} entrou na sala {roomId}");
    }

    public async Task LeaveRoom(string roomId, string userId)
    {
        var user = _userService.GetUser(userId);
        if (user == null) return;

        _userService.RemoveUserFromRoom(userId, roomId);
        _chatService.LeaveRoom(roomId, userId);

        await Groups.RemoveFromGroupAsync(Context.ConnectionId, roomId);

        // Enviar mensagem de sistema
        var systemMessage = new ChatMessage
        {
            Content = $"{user.Name} saiu da sala",
            SenderId = "system",
            SenderName = "Sistema",
            SenderAvatar = "",
            Type = MessageType.System,
            RoomId = roomId
        };

        _chatService.AddMessage(systemMessage);
        await Clients.Group(roomId).SendAsync("MessageReceived", systemMessage);

        _logger.LogInformation($"Usuário {user.Name} saiu da sala {roomId}");
    }

    public async Task SendMessage(string roomId, string userId, string content, string? replyToMessageId = null)
    {
        var user = _userService.GetUser(userId);
        if (user == null)
        {
            await Clients.Caller.SendAsync("Error", "Usuário não encontrado");
            return;
        }

        var message = new ChatMessage
        {
            Content = content,
            SenderId = userId,
            SenderName = user.Name,
            SenderAvatar = user.Avatar,
            RoomId = roomId,
            ReplyToMessageId = replyToMessageId,
            Status = MessageStatus.Sent
        };

        if (!string.IsNullOrEmpty(replyToMessageId))
        {
            var replyMessage = _chatService.GetRoomMessages(roomId)
                .FirstOrDefault(m => m.Id == replyToMessageId);
            message.ReplyToMessage = replyMessage;
        }

        _chatService.AddMessage(message);
        await Clients.Group(roomId).SendAsync("MessageReceived", message);

        _logger.LogInformation($"Mensagem enviada por {user.Name} na sala {roomId}: {content}");
    }

    public async Task EditMessage(string messageId, string newContent, string userId)
    {
        var success = _chatService.EditMessage(messageId, newContent, userId);
        if (success)
        {
            var message = _chatService.GetRoomMessages("general")
                .FirstOrDefault(m => m.Id == messageId);
            
            if (message != null)
            {
                await Clients.Group(message.RoomId!).SendAsync("MessageEdited", message);
            }
        }
        else
        {
            await Clients.Caller.SendAsync("Error", "Não foi possível editar a mensagem");
        }
    }

    public async Task DeleteMessage(string messageId, string userId)
    {
        var success = _chatService.DeleteMessage(messageId, userId);
        if (success)
        {
            await Clients.All.SendAsync("MessageDeleted", messageId);
        }
        else
        {
            await Clients.Caller.SendAsync("Error", "Não foi possível deletar a mensagem");
        }
    }

    public async Task AddReaction(string messageId, string userId, string reaction)
    {
        _chatService.AddReaction(messageId, userId, reaction);
        await Clients.All.SendAsync("ReactionAdded", messageId, userId, reaction);
    }

    public async Task RemoveReaction(string messageId, string userId, string reaction)
    {
        _chatService.RemoveReaction(messageId, userId, reaction);
        await Clients.All.SendAsync("ReactionRemoved", messageId, userId, reaction);
    }

    public async Task StartTyping(string roomId, string userId)
    {
        _chatService.SetTyping(roomId, userId, true);
        var user = _userService.GetUser(userId);
        if (user != null)
        {
            await Clients.Group(roomId).SendAsync("UserTyping", roomId, user.Name);
        }
    }

    public async Task StopTyping(string roomId, string userId)
    {
        _chatService.SetTyping(roomId, userId, false);
        var user = _userService.GetUser(userId);
        if (user != null)
        {
            await Clients.Group(roomId).SendAsync("UserStoppedTyping", roomId, user.Name);
        }
    }

    public async Task CreateRoom(string name, string description, string creatorId)
    {
        var room = _chatService.CreateRoom(name, description, RoomType.Public, creatorId);
        await Clients.All.SendAsync("RoomCreated", room);
    }

    public async Task GetRooms()
    {
        var rooms = _chatService.GetAllRooms();
        await Clients.Caller.SendAsync("RoomsList", rooms);
    }

    public async Task GetOnlineUsers()
    {
        var users = _userService.GetOnlineUsers();
        await Clients.Caller.SendAsync("OnlineUsers", users);
    }

    public async Task UpdateUserStatus(string userId, UserStatus status)
    {
        var success = _userService.UpdateUserStatus(userId, status);
        if (success)
        {
            await NotifyUserStatusChange(userId, status);
        }
    }

    public async Task UpdateUserProfile(string userId, string name, string avatar)
    {
        var success = _userService.UpdateUserProfile(userId, name, avatar);
        if (success)
        {
            var user = _userService.GetUser(userId);
            await Clients.All.SendAsync("UserProfileUpdated", user);
        }
    }

    private async Task NotifyUserStatusChange(string userId, UserStatus status)
    {
        var user = _userService.GetUser(userId);
        if (user != null)
        {
            await Clients.All.SendAsync("UserStatusChanged", userId, status, user.Name);
        }
    }

    public async Task MarkMessageAsRead(string messageId, string userId)
    {
        // Implementar lógica de confirmação de leitura
        await Clients.All.SendAsync("MessageRead", messageId, userId);
    }

    public async Task GetMessageHistory(string roomId, int limit = 50, int offset = 0)
    {
        var messages = _chatService.GetRoomMessages(roomId, limit, offset);
        await Clients.Caller.SendAsync("MessageHistory", messages);
    }
}
