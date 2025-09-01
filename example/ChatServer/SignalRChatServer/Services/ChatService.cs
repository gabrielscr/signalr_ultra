using SignalRChatServer.Models;

namespace SignalRChatServer.Services;

public class ChatService
{
    private readonly Dictionary<string, ChatRoom> _rooms = new();
    private readonly Dictionary<string, List<ChatMessage>> _messages = new();
    private readonly Dictionary<string, List<string>> _userRooms = new();
    private readonly Dictionary<string, DateTime> _typingUsers = new();

    public ChatService()
    {
        // Criar sala geral padrão
        var generalRoom = new ChatRoom
        {
            Id = "general",
            Name = "Geral",
            Description = "Sala principal para conversas gerais",
            Type = RoomType.Public
        };
        _rooms[generalRoom.Id] = generalRoom;
        _messages[generalRoom.Id] = new List<ChatMessage>();
    }

    public ChatRoom? GetRoom(string roomId)
    {
        return _rooms.GetValueOrDefault(roomId);
    }

    public List<ChatRoom> GetAllRooms()
    {
        return _rooms.Values.ToList();
    }

    public List<ChatMessage> GetRoomMessages(string roomId, int limit = 50, int offset = 0)
    {
        if (!_messages.ContainsKey(roomId))
            return new List<ChatMessage>();

        return _messages[roomId]
            .OrderByDescending(m => m.Timestamp)
            .Skip(offset)
            .Take(limit)
            .Reverse()
            .ToList();
    }

    public ChatMessage AddMessage(ChatMessage message)
    {
        if (!_messages.ContainsKey(message.RoomId!))
            _messages[message.RoomId!] = new List<ChatMessage>();

        _messages[message.RoomId!].Add(message);

        // Atualizar última atividade da sala
        if (_rooms.ContainsKey(message.RoomId!))
        {
            _rooms[message.RoomId!].LastActivity = DateTime.UtcNow;
            _rooms[message.RoomId!].MessageCount++;
            _rooms[message.RoomId!].LastMessageId = message.Id;
            _rooms[message.RoomId!].LastMessage = message;
        }

        return message;
    }

    public bool EditMessage(string messageId, string newContent, string userId)
    {
        foreach (var roomMessages in _messages.Values)
        {
            var message = roomMessages.FirstOrDefault(m => m.Id == messageId && m.SenderId == userId);
            if (message != null)
            {
                message.Content = newContent;
                message.IsEdited = true;
                message.EditedAt = DateTime.UtcNow;
                return true;
            }
        }
        return false;
    }

    public bool DeleteMessage(string messageId, string userId)
    {
        foreach (var roomMessages in _messages.Values)
        {
            var message = roomMessages.FirstOrDefault(m => m.Id == messageId && m.SenderId == userId);
            if (message != null)
            {
                roomMessages.Remove(message);
                return true;
            }
        }
        return false;
    }

    public void AddReaction(string messageId, string userId, string reaction)
    {
        foreach (var roomMessages in _messages.Values)
        {
            var message = roomMessages.FirstOrDefault(m => m.Id == messageId);
            if (message != null)
            {
                var reactionKey = $"{userId}:{reaction}";
                if (!message.Reactions.Contains(reactionKey))
                {
                    message.Reactions.Add(reactionKey);
                }
                break;
            }
        }
    }

    public void RemoveReaction(string messageId, string userId, string reaction)
    {
        foreach (var roomMessages in _messages.Values)
        {
            var message = roomMessages.FirstOrDefault(m => m.Id == messageId);
            if (message != null)
            {
                var reactionKey = $"{userId}:{reaction}";
                message.Reactions.Remove(reactionKey);
                break;
            }
        }
    }

    public void SetTyping(string roomId, string userId, bool isTyping)
    {
        var key = $"{roomId}:{userId}";
        if (isTyping)
        {
            _typingUsers[key] = DateTime.UtcNow;
        }
        else
        {
            _typingUsers.Remove(key);
        }
    }

    public List<string> GetTypingUsers(string roomId)
    {
        var cutoff = DateTime.UtcNow.AddSeconds(-10); // Remover usuários que pararam de digitar há mais de 10 segundos
        var typingUsers = _typingUsers
            .Where(kvp => kvp.Key.StartsWith($"{roomId}:") && kvp.Value > cutoff)
            .Select(kvp => kvp.Key.Split(':')[1])
            .ToList();

        // Limpar usuários antigos
        var toRemove = _typingUsers
            .Where(kvp => kvp.Key.StartsWith($"{roomId}:") && kvp.Value <= cutoff)
            .Select(kvp => kvp.Key)
            .ToList();

        foreach (var key in toRemove)
        {
            _typingUsers.Remove(key);
        }

        return typingUsers;
    }

    public ChatRoom CreateRoom(string name, string description, RoomType type, string creatorId)
    {
        var room = new ChatRoom
        {
            Id = Guid.NewGuid().ToString(),
            Name = name,
            Description = description,
            Type = type,
            Members = new List<string> { creatorId },
            Admins = new List<string> { creatorId }
        };

        _rooms[room.Id] = room;
        _messages[room.Id] = new List<ChatMessage>();

        return room;
    }

    public bool JoinRoom(string roomId, string userId)
    {
        if (_rooms.ContainsKey(roomId) && !_rooms[roomId].Members.Contains(userId))
        {
            _rooms[roomId].Members.Add(userId);
            return true;
        }
        return false;
    }

    public bool LeaveRoom(string roomId, string userId)
    {
        if (_rooms.ContainsKey(roomId) && _rooms[roomId].Members.Contains(userId))
        {
            _rooms[roomId].Members.Remove(userId);
            return true;
        }
        return false;
    }
}
