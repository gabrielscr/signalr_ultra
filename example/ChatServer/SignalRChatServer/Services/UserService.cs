using SignalRChatServer.Models;

namespace SignalRChatServer.Services;

public class UserService
{
    private readonly Dictionary<string, User> _users = new();
    private readonly Dictionary<string, string> _connectionUserMap = new();

    public UserService()
    {
        // Criar alguns usuários de exemplo
        var users = new[]
        {
            new User { Id = "1", Name = "Alice Silva", Email = "alice@example.com", Avatar = "https://i.pravatar.cc/150?img=1" },
            new User { Id = "2", Name = "Bob Santos", Email = "bob@example.com", Avatar = "https://i.pravatar.cc/150?img=2" },
            new User { Id = "3", Name = "Carol Costa", Email = "carol@example.com", Avatar = "https://i.pravatar.cc/150?img=3" },
            new User { Id = "4", Name = "David Oliveira", Email = "david@example.com", Avatar = "https://i.pravatar.cc/150?img=4" },
            new User { Id = "5", Name = "Eva Pereira", Email = "eva@example.com", Avatar = "https://i.pravatar.cc/150?img=5" }
        };

        foreach (var user in users)
        {
            _users[user.Id] = user;
        }
    }

    public User? GetUser(string userId)
    {
        return _users.GetValueOrDefault(userId);
    }

    public List<User> GetAllUsers()
    {
        return _users.Values.ToList();
    }

    public List<User> GetOnlineUsers()
    {
        return _users.Values.Where(u => u.Status == UserStatus.Online).ToList();
    }

    public User CreateUser(string name, string email, string avatar = "")
    {
        var user = new User
        {
            Id = Guid.NewGuid().ToString(),
            Name = name,
            Email = email,
            Avatar = string.IsNullOrEmpty(avatar) ? $"https://i.pravatar.cc/150?img={_users.Count + 1}" : avatar,
            Status = UserStatus.Online,
            LastSeen = DateTime.UtcNow
        };

        _users[user.Id] = user;
        return user;
    }

    public bool UpdateUserStatus(string userId, UserStatus status)
    {
        if (_users.ContainsKey(userId))
        {
            _users[userId].Status = status;
            _users[userId].LastSeen = DateTime.UtcNow;
            return true;
        }
        return false;
    }

    public bool UpdateUserProfile(string userId, string name, string avatar)
    {
        if (_users.ContainsKey(userId))
        {
            _users[userId].Name = name;
            if (!string.IsNullOrEmpty(avatar))
            {
                _users[userId].Avatar = avatar;
            }
            return true;
        }
        return false;
    }

    public void MapConnectionToUser(string connectionId, string userId)
    {
        _connectionUserMap[connectionId] = userId;
        if (_users.ContainsKey(userId))
        {
            _users[userId].Status = UserStatus.Online;
            _users[userId].LastSeen = DateTime.UtcNow;
        }
    }

    public void RemoveConnection(string connectionId)
    {
        if (_connectionUserMap.TryGetValue(connectionId, out var userId))
        {
            _connectionUserMap.Remove(connectionId);
            if (_users.ContainsKey(userId))
            {
                _users[userId].Status = UserStatus.Offline;
                _users[userId].LastSeen = DateTime.UtcNow;
            }
        }
    }

    public string? GetUserIdByConnection(string connectionId)
    {
        return _connectionUserMap.GetValueOrDefault(connectionId);
    }

    public List<string> GetUserConnections(string userId)
    {
        return _connectionUserMap
            .Where(kvp => kvp.Value == userId)
            .Select(kvp => kvp.Key)
            .ToList();
    }

    public void UpdateUserPreferences(string userId, Dictionary<string, object> preferences)
    {
        if (_users.ContainsKey(userId))
        {
            foreach (var pref in preferences)
            {
                _users[userId].Preferences[pref.Key] = pref.Value;
            }
        }
    }

    public Dictionary<string, object> GetUserPreferences(string userId)
    {
        return _users.GetValueOrDefault(userId)?.Preferences ?? new Dictionary<string, object>();
    }

    public void AddUserToRoom(string userId, string roomId)
    {
        if (_users.ContainsKey(userId) && !_users[userId].ConnectedRooms.Contains(roomId))
        {
            _users[userId].ConnectedRooms.Add(roomId);
        }
    }

    public void RemoveUserFromRoom(string userId, string roomId)
    {
        if (_users.ContainsKey(userId))
        {
            _users[userId].ConnectedRooms.Remove(roomId);
        }
    }

    public List<string> GetUserRooms(string userId)
    {
        return _users.GetValueOrDefault(userId)?.ConnectedRooms ?? new List<string>();
    }
}
