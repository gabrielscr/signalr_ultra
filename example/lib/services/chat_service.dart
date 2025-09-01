import 'dart:async';
import 'dart:convert';
import 'package:signalr_ultra/signalr_ultra.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';
import '../models/chat_message.dart';
import '../models/user.dart';
import '../models/chat_room.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final Logger _logger = Logger('ChatService');
  SignalRClient? _client;
  
  // Streams para notificações em tempo real
  final BehaviorSubject<ConnectionState> _connectionState = BehaviorSubject<ConnectionState>();
  final BehaviorSubject<List<ChatMessage>> _messages = BehaviorSubject<List<ChatMessage>>();
  final BehaviorSubject<List<User>> _onlineUsers = BehaviorSubject<List<User>>();
  final BehaviorSubject<List<ChatRoom>> _rooms = BehaviorSubject<List<ChatRoom>>();
  final BehaviorSubject<List<String>> _typingUsers = BehaviorSubject<List<String>>();
  final BehaviorSubject<ChatMessage?> _newMessage = BehaviorSubject<ChatMessage?>();
  final BehaviorSubject<String> _error = BehaviorSubject<String>();

  // Getters para streams
  Stream<ConnectionState> get connectionState => _connectionState.stream;
  Stream<List<ChatMessage>> get messages => _messages.stream;
  Stream<List<User>> get onlineUsers => _onlineUsers.stream;
  Stream<List<ChatRoom>> get rooms => _rooms.stream;
  Stream<List<String>> get typingUsers => _typingUsers.stream;
  Stream<ChatMessage?> get newMessage => _newMessage.stream;
  Stream<String> get error => _error.stream;

  // Estado atual
  String? _currentUserId;
  String? _currentRoomId;
  List<ChatMessage> _messageList = [];
  List<User> _userList = [];
  List<ChatRoom> _roomList = [];
  List<String> _typingList = [];

  // Configuração
  static const String _serverUrl = 'http://localhost:5000';
  static const String _chatHub = '/chatHub';

  Future<void> initialize() async {
    try {
      // Usar o builder pattern para criar o cliente
      _client = SignalRClient.builder()
        .withUrl('$_serverUrl$_chatHub')
        .withLogLevel(LogLevel.info)
        .withLogPrefix('CHAT_SERVICE')
        .withTimeout(const Duration(seconds: 30))
        .build();

      // Conectar ao hub
      final metadata = await _client!.connect(
        url: '$_serverUrl$_chatHub',
        timeout: const Duration(seconds: 30),
      );

      _connectionState.add(_client!.state);
      _setupEventHandlers();
      _logger.info('ChatService inicializado com sucesso - ConnectionId: ${metadata.connectionId}');
    } catch (e) {
      _logger.severe('Erro ao inicializar ChatService: $e');
      _error.add('Erro de conexão: $e');
    }
  }

  void _setupEventHandlers() {
    _client?.on('MessageReceived', (data) {
      try {
        final message = ChatMessage.fromJson(data);
        _addMessage(message);
        _newMessage.add(message);
        _logger.info('Nova mensagem recebida: ${message.content}');
      } catch (e) {
        _logger.warning('Erro ao processar mensagem: $e');
      }
    });

    _client?.on('MessageHistory', (data) {
      try {
        final List<dynamic> messagesJson = data;
        final messages = messagesJson
            .map((json) => ChatMessage.fromJson(json))
            .toList();
        _messageList = messages;
        _messages.add(_messageList);
        _logger.info('Histórico de mensagens carregado: ${messages.length} mensagens');
      } catch (e) {
        _logger.warning('Erro ao processar histórico: $e');
      }
    });

    _client?.on('OnlineUsers', (data) {
      try {
        final List<dynamic> usersJson = data;
        final users = usersJson
            .map((json) => User.fromJson(json))
            .toList();
        _userList = users;
        _onlineUsers.add(_userList);
        _logger.info('Usuários online atualizados: ${users.length} usuários');
      } catch (e) {
        _logger.warning('Erro ao processar usuários online: $e');
      }
    });

    _client?.on('RoomsList', (data) {
      try {
        final List<dynamic> roomsJson = data;
        final rooms = roomsJson
            .map((json) => ChatRoom.fromJson(json))
            .toList();
        _roomList = rooms;
        _rooms.add(_roomList);
        _logger.info('Lista de salas atualizada: ${rooms.length} salas');
      } catch (e) {
        _logger.warning('Erro ao processar lista de salas: $e');
      }
    });

    _client?.on('UserTyping', (data) {
      try {
        final userId = data[0] as String;
        final isTyping = data[1] as bool;
        
        if (isTyping) {
          if (!_typingList.contains(userId)) {
            _typingList.add(userId);
          }
        } else {
          _typingList.remove(userId);
        }
        
        _typingUsers.add(_typingList);
        _logger.info('Usuário ${isTyping ? 'começou' : 'parou'} de digitar: $userId');
      } catch (e) {
        _logger.warning('Erro ao processar status de digitação: $e');
      }
    });

    // Monitorar mudanças de estado da conexão
    _client?.stateStream.listen((state) {
      _connectionState.add(state);
      _logger.info('Estado da conexão alterado: $state');
      
      if (state == ConnectionState.failed) {
        _error.add('Conexão falhou');
      }
    });
  }

  Future<void> joinRoom(String roomId, String userId) async {
    try {
      _currentRoomId = roomId;
      _currentUserId = userId;
      
      await _client?.invoke('JoinRoom', arguments: [roomId, userId]);
      _logger.info('Entrou na sala: $roomId');
    } catch (e) {
      _logger.severe('Erro ao entrar na sala: $e');
      _error.add('Erro ao entrar na sala: $e');
    }
  }

  Future<void> leaveRoom(String roomId, String userId) async {
    try {
      await _client?.invoke('LeaveRoom', arguments: [roomId, userId]);
      if (_currentRoomId == roomId) {
        _currentRoomId = null;
      }
      _logger.info('Saiu da sala: $roomId');
    } catch (e) {
      _logger.severe('Erro ao sair da sala: $e');
      _error.add('Erro ao sair da sala: $e');
    }
  }

  Future<void> sendMessage(String content, {String? replyToMessageId}) async {
    if (_currentRoomId == null || _currentUserId == null) {
      _error.add('Não está conectado a uma sala');
      return;
    }

    try {
      final args = [_currentRoomId!, _currentUserId!, content];
      if (replyToMessageId != null) {
        args.add(replyToMessageId);
      }
      
      await _client?.invoke('SendMessage', arguments: args);
      _logger.info('Mensagem enviada: $content');
    } catch (e) {
      _logger.severe('Erro ao enviar mensagem: $e');
      _error.add('Erro ao enviar mensagem: $e');
    }
  }

  Future<void> editMessage(String messageId, String newContent) async {
    if (_currentUserId == null) {
      _error.add('Usuário não identificado');
      return;
    }

    try {
      await _client?.invoke('EditMessage', arguments: [messageId, newContent, _currentUserId!]);
      _logger.info('Mensagem editada: $messageId');
    } catch (e) {
      _logger.severe('Erro ao editar mensagem: $e');
      _error.add('Erro ao editar mensagem: $e');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    if (_currentUserId == null) {
      _error.add('Usuário não identificado');
      return;
    }

    try {
      await _client?.invoke('DeleteMessage', arguments: [messageId, _currentUserId!]);
      _logger.info('Mensagem deletada: $messageId');
    } catch (e) {
      _logger.severe('Erro ao deletar mensagem: $e');
      _error.add('Erro ao deletar mensagem: $e');
    }
  }

  Future<void> addReaction(String messageId, String reaction) async {
    if (_currentUserId == null) {
      _error.add('Usuário não identificado');
      return;
    }

    try {
      await _client?.invoke('AddReaction', arguments: [messageId, _currentUserId!, reaction]);
      _logger.info('Reação adicionada: $reaction');
    } catch (e) {
      _logger.severe('Erro ao adicionar reação: $e');
      _error.add('Erro ao adicionar reação: $e');
    }
  }

  Future<void> removeReaction(String messageId, String reaction) async {
    if (_currentUserId == null) {
      _error.add('Usuário não identificado');
      return;
    }

    try {
      await _client?.invoke('RemoveReaction', arguments: [messageId, _currentUserId!, reaction]);
      _logger.info('Reação removida: $reaction');
    } catch (e) {
      _logger.severe('Erro ao remover reação: $e');
      _error.add('Erro ao remover reação: $e');
    }
  }

  Future<void> startTyping() async {
    if (_currentRoomId == null || _currentUserId == null) {
      return;
    }

    try {
      await _client?.invoke('StartTyping', arguments: [_currentRoomId!, _currentUserId!]);
    } catch (e) {
      _logger.warning('Erro ao iniciar digitação: $e');
    }
  }

  Future<void> stopTyping() async {
    if (_currentRoomId == null || _currentUserId == null) {
      return;
    }

    try {
      await _client?.invoke('StopTyping', arguments: [_currentRoomId!, _currentUserId!]);
    } catch (e) {
      _logger.warning('Erro ao parar digitação: $e');
    }
  }

  Future<void> getRooms() async {
    try {
      await _client?.invoke('GetRooms');
    } catch (e) {
      _logger.severe('Erro ao obter salas: $e');
      _error.add('Erro ao obter salas: $e');
    }
  }

  Future<void> getOnlineUsers() async {
    try {
      await _client?.invoke('GetOnlineUsers');
    } catch (e) {
      _logger.severe('Erro ao obter usuários online: $e');
      _error.add('Erro ao obter usuários online: $e');
    }
  }

  Future<void> createRoom(String name, String description) async {
    if (_currentUserId == null) {
      _error.add('Usuário não identificado');
      return;
    }

    try {
      await _client?.invoke('CreateRoom', arguments: [name, description, _currentUserId!]);
      _logger.info('Sala criada: $name');
    } catch (e) {
      _logger.severe('Erro ao criar sala: $e');
      _error.add('Erro ao criar sala: $e');
    }
  }

  void _addMessage(ChatMessage message) {
    _messageList.add(message);
    _messages.add(_messageList);
  }

  void _updateMessage(ChatMessage updatedMessage) {
    final index = _messageList.indexWhere((msg) => msg.id == updatedMessage.id);
    if (index != -1) {
      _messageList[index] = updatedMessage;
      _messages.add(_messageList);
    }
  }

  void _removeMessage(String messageId) {
    _messageList.removeWhere((msg) => msg.id == messageId);
    _messages.add(_messageList);
  }

  void _addReaction(String messageId, String userId, String reaction) {
    final message = _messageList.firstWhere((msg) => msg.id == messageId);
    final updatedReactions = List<String>.from(message.reactions)..add(reaction);
    final updatedMessage = message.copyWith(reactions: updatedReactions);
    _updateMessage(updatedMessage);
  }

  void _removeReaction(String messageId, String userId, String reaction) {
    final message = _messageList.firstWhere((msg) => msg.id == messageId);
    final updatedReactions = List<String>.from(message.reactions)..remove(reaction);
    final updatedMessage = message.copyWith(reactions: updatedReactions);
    _updateMessage(updatedMessage);
  }

  Future<void> disconnect() async {
    try {
      await _client?.disconnect();
      _logger.info('ChatService desconectado');
    } catch (e) {
      _logger.severe('Erro ao desconectar: $e');
    }
  }

  void dispose() {
    _connectionState.close();
    _messages.close();
    _onlineUsers.close();
    _rooms.close();
    _typingUsers.close();
    _newMessage.close();
    _error.close();
    disconnect();
  }
}
