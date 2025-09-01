import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signalr_ultra/signalr_ultra.dart';
import '../models/chat_message.dart';
import '../models/user.dart';
import '../models/chat_room.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  
  // Estado da aplicação
  ConnectionState _connectionState = ConnectionState.disconnected;
  List<ChatMessage> _messages = [];
  List<User> _onlineUsers = [];
  List<ChatRoom> _rooms = [];
  List<String> _typingUsers = [];
  String? _currentUserId;
  String? _currentRoomId;
  String? _error;
  bool _isLoading = false;

  // Getters
  ConnectionState get connectionState => _connectionState;
  List<ChatMessage> get messages => _messages;
  List<User> get onlineUsers => _onlineUsers;
  List<ChatRoom> get rooms => _rooms;
  List<String> get typingUsers => _typingUsers;
  String? get currentUserId => _currentUserId;
  String? get currentRoomId => _currentRoomId;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isConnected => _connectionState == ConnectionState.connected;

  // Stream subscriptions
  StreamSubscription<ConnectionState>? _connectionSubscription;
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;
  StreamSubscription<List<User>>? _usersSubscription;
  StreamSubscription<List<ChatRoom>>? _roomsSubscription;
  StreamSubscription<List<String>>? _typingSubscription;
  StreamSubscription<String>? _errorSubscription;

  ChatProvider() {
    _initializeStreams();
  }

  void _initializeStreams() {
    _connectionSubscription = _chatService.connectionState.listen((state) {
      _connectionState = state;
      notifyListeners();
    });

    _messagesSubscription = _chatService.messages.listen((messages) {
      _messages = messages;
      notifyListeners();
    });

    _usersSubscription = _chatService.onlineUsers.listen((users) {
      _onlineUsers = users;
      notifyListeners();
    });

    _roomsSubscription = _chatService.rooms.listen((rooms) {
      _rooms = rooms;
      notifyListeners();
    });

    _typingSubscription = _chatService.typingUsers.listen((typingUsers) {
      _typingUsers = typingUsers;
      notifyListeners();
    });

    _errorSubscription = _chatService.error.listen((error) {
      _error = error;
      notifyListeners();
    });
  }

  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _chatService.initialize();
      _error = null;
    } catch (e) {
      _error = 'Erro ao inicializar: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> joinRoom(String roomId, String userId) async {
    _setLoading(true);
    try {
      await _chatService.joinRoom(roomId, userId);
      _currentRoomId = roomId;
      _currentUserId = userId;
      _error = null;
    } catch (e) {
      _error = 'Erro ao entrar na sala: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> leaveRoom(String roomId, String userId) async {
    try {
      await _chatService.leaveRoom(roomId, userId);
      if (_currentRoomId == roomId) {
        _currentRoomId = null;
      }
      _error = null;
    } catch (e) {
      _error = 'Erro ao sair da sala: $e';
    }
  }

  Future<void> sendMessage(String content, {String? replyToMessageId}) async {
    if (content.trim().isEmpty) return;

    try {
      await _chatService.sendMessage(content, replyToMessageId: replyToMessageId);
      _error = null;
    } catch (e) {
      _error = 'Erro ao enviar mensagem: $e';
    }
  }

  Future<void> editMessage(String messageId, String newContent) async {
    if (newContent.trim().isEmpty) return;

    try {
      await _chatService.editMessage(messageId, newContent);
      _error = null;
    } catch (e) {
      _error = 'Erro ao editar mensagem: $e';
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _chatService.deleteMessage(messageId);
      _error = null;
    } catch (e) {
      _error = 'Erro ao deletar mensagem: $e';
    }
  }

  Future<void> addReaction(String messageId, String reaction) async {
    try {
      await _chatService.addReaction(messageId, reaction);
      _error = null;
    } catch (e) {
      _error = 'Erro ao adicionar reação: $e';
    }
  }

  Future<void> removeReaction(String messageId, String reaction) async {
    try {
      await _chatService.removeReaction(messageId, reaction);
      _error = null;
    } catch (e) {
      _error = 'Erro ao remover reação: $e';
    }
  }

  Future<void> startTyping() async {
    try {
      await _chatService.startTyping();
    } catch (e) {
      // Erro de digitação não é crítico
    }
  }

  Future<void> stopTyping() async {
    try {
      await _chatService.stopTyping();
    } catch (e) {
      // Erro de digitação não é crítico
    }
  }

  Future<void> getRooms() async {
    try {
      await _chatService.getRooms();
      _error = null;
    } catch (e) {
      _error = 'Erro ao obter salas: $e';
    }
  }

  Future<void> getOnlineUsers() async {
    try {
      await _chatService.getOnlineUsers();
      _error = null;
    } catch (e) {
      _error = 'Erro ao obter usuários online: $e';
    }
  }

  Future<void> createRoom(String name, String description) async {
    if (name.trim().isEmpty) return;

    _setLoading(true);
    try {
      await _chatService.createRoom(name, description);
      _error = null;
    } catch (e) {
      _error = 'Erro ao criar sala: $e';
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Métodos auxiliares
  ChatMessage? getMessageById(String messageId) {
    try {
      return _messages.firstWhere((message) => message.id == messageId);
    } catch (e) {
      return null;
    }
  }

  User? getUserById(String userId) {
    try {
      return _onlineUsers.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  ChatRoom? getRoomById(String roomId) {
    try {
      return _rooms.firstWhere((room) => room.id == roomId);
    } catch (e) {
      return null;
    }
  }

  bool isCurrentUser(String userId) {
    return _currentUserId == userId;
  }

  bool isCurrentRoom(String roomId) {
    return _currentRoomId == roomId;
  }

  List<ChatMessage> getMessagesForRoom(String roomId) {
    return _messages.where((message) => message.roomId == roomId).toList();
  }

  List<User> getUsersInRoom(String roomId) {
    final room = getRoomById(roomId);
    if (room == null) return [];
    
    return _onlineUsers.where((user) => room.members.contains(user.id)).toList();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _messagesSubscription?.cancel();
    _usersSubscription?.cancel();
    _roomsSubscription?.cancel();
    _typingSubscription?.cancel();
    _errorSubscription?.cancel();
    _chatService.dispose();
    super.dispose();
  }
}
