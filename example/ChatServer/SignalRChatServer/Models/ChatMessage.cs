using System.Text.Json.Serialization;

namespace SignalRChatServer.Models;

public class ChatMessage
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Content { get; set; } = string.Empty;
    public string SenderId { get; set; } = string.Empty;
    public string SenderName { get; set; } = string.Empty;
    public string SenderAvatar { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public MessageType Type { get; set; } = MessageType.Text;
    public string? RoomId { get; set; }
    public bool IsEdited { get; set; } = false;
    public DateTime? EditedAt { get; set; }
    public List<string> Reactions { get; set; } = new();
    public MessageStatus Status { get; set; } = MessageStatus.Sent;
    public string? ReplyToMessageId { get; set; }
    public ChatMessage? ReplyToMessage { get; set; }
    public Dictionary<string, object> Metadata { get; set; } = new();
}

public enum MessageType
{
    Text,
    Image,
    File,
    Audio,
    Video,
    Location,
    System,
    Typing,
    ReadReceipt
}

public enum MessageStatus
{
    Sending,
    Sent,
    Delivered,
    Read,
    Failed
}

public class User
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Avatar { get; set; } = string.Empty;
    public UserStatus Status { get; set; } = UserStatus.Online;
    public DateTime LastSeen { get; set; } = DateTime.UtcNow;
    public List<string> ConnectedRooms { get; set; } = new();
    public Dictionary<string, object> Preferences { get; set; } = new();
}

public enum UserStatus
{
    Online,
    Away,
    Busy,
    Offline
}

public class ChatRoom
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public RoomType Type { get; set; } = RoomType.Public;
    public List<string> Members { get; set; } = new();
    public List<string> Admins { get; set; } = new();
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime LastActivity { get; set; } = DateTime.UtcNow;
    public int MessageCount { get; set; } = 0;
    public string? LastMessageId { get; set; }
    public ChatMessage? LastMessage { get; set; }
}

public enum RoomType
{
    Public,
    Private,
    Direct
}
