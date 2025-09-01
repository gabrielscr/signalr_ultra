import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/chat_provider.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../models/user.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  Timer? _typingTimer;
  ChatRoom? _currentRoom;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currentRoom = ModalRoute.of(context)!.settings.arguments as ChatRoom?;
      if (_currentRoom != null) {
        _joinRoom();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    if (_currentRoom == null) return;
    
    final chatProvider = context.read<ChatProvider>();
    final currentUserId = chatProvider.currentUserId;
    
    if (currentUserId != null) {
      await chatProvider.joinRoom(_currentRoom!.id, currentUserId);
    }
  }

  void _onMessageChanged(String text) {
    final chatProvider = context.read<ChatProvider>();
    
    if (!_isTyping) {
      _isTyping = true;
      chatProvider.startTyping();
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1000), () {
      _isTyping = false;
      chatProvider.stopTyping();
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatProvider = context.read<ChatProvider>();
    await chatProvider.sendMessage(text);
    
    _messageController.clear();
    _isTyping = false;
    chatProvider.stopTyping();
    _typingTimer?.cancel();
    
    // Scroll para baixo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showMessageOptions(ChatMessage message) {
    final chatProvider = context.read<ChatProvider>();
    final isCurrentUser = chatProvider.isCurrentUser(message.senderId);
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrentUser) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditMessageDialog(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Deletar', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Responder'),
              onTap: () {
                Navigator.pop(context);
                _replyToMessage(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copiar'),
              onTap: () {
                Navigator.pop(context);
                _copyMessage(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMessageDialog(ChatMessage message) {
    final controller = TextEditingController(text: message.content);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Mensagem'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nova mensagem',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty) {
                Navigator.pop(context);
                await context.read<ChatProvider>().editMessage(message.id, newContent);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar Mensagem'),
        content: const Text('Tem certeza que deseja deletar esta mensagem?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<ChatProvider>().deleteMessage(message.id);
    }
  }

  void _replyToMessage(ChatMessage message) {
    _messageController.text = 'Replying to: ${message.content}';
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _copyMessage(ChatMessage message) {
    // Implementar cópia para clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mensagem copiada para clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _currentRoom != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_currentRoom!.name),
                  Text(
                    '${_currentRoom!.members.length} membros',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              )
            : const Text('Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Mostrar informações da sala
            },
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final messages = chatProvider.getMessagesForRoom(_currentRoom?.id ?? '');
          
          return Column(
            children: [
              // Status da conexão
              if (chatProvider.error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          chatProvider.error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: chatProvider.clearError,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ],
                  ),
                ),
              
              // Lista de mensagens
              Expanded(
                child: messages.isEmpty
                    ? _buildEmptyState()
                    : AnimationLimiter(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 375),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: MessageBubble(
                                    message: message,
                                    isCurrentUser: chatProvider.isCurrentUser(message.senderId),
                                    onTap: () => _showMessageOptions(message),
                                    onReaction: (reaction) {
                                      chatProvider.addReaction(message.id, reaction);
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              
              // Indicador de digitação
              if (chatProvider.typingUsers.isNotEmpty)
                TypingIndicator(
                  users: chatProvider.typingUsers,
                ),
              
              // Campo de entrada
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Botão de anexo
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: () {
                        // Implementar anexo de arquivo
                      },
                    ),
                    
                    // Campo de texto
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        onChanged: _onMessageChanged,
                        decoration: InputDecoration(
                          hintText: 'Digite sua mensagem...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Botão de enviar
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma mensagem ainda',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seja o primeiro a enviar uma mensagem!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
