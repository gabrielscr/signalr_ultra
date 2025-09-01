import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/chat_provider.dart';
import '../models/user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedAvatar = '';
  bool _isLoading = false;

  // Usuários de exemplo
  final List<Map<String, String>> _exampleUsers = [
    {
      'id': '1',
      'name': 'Alice Silva',
      'email': 'alice@example.com',
      'avatar': 'https://i.pravatar.cc/150?img=1',
    },
    {
      'id': '2',
      'name': 'Bob Santos',
      'email': 'bob@example.com',
      'avatar': 'https://i.pravatar.cc/150?img=2',
    },
    {
      'id': '3',
      'name': 'Carol Costa',
      'email': 'carol@example.com',
      'avatar': 'https://i.pravatar.cc/150?img=3',
    },
    {
      'id': '4',
      'name': 'David Oliveira',
      'email': 'david@example.com',
      'avatar': 'https://i.pravatar.cc/150?img=4',
    },
    {
      'id': '5',
      'name': 'Eva Pereira',
      'email': 'eva@example.com',
      'avatar': 'https://i.pravatar.cc/150?img=5',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Selecionar primeiro usuário por padrão
    if (_exampleUsers.isNotEmpty) {
      _selectedAvatar = _exampleUsers[0]['avatar']!;
      _nameController.text = _exampleUsers[0]['name']!;
      _emailController.text = _exampleUsers[0]['email']!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final chatProvider = context.read<ChatProvider>();
      await chatProvider.initialize();
      
      // Simular login com usuário selecionado
      final selectedUser = _exampleUsers.firstWhere(
        (user) => user['avatar'] == _selectedAvatar,
      );

      await chatProvider.joinRoom('general', selectedUser['id']!);
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/rooms');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao conectar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Logo e título
                Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        size: 50,
                        color: Colors.white,
                      ),
                    ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      'Bem-vindo ao Chat',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Escolha um usuário para começar',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Seleção de usuários
                Text(
                  'Usuários Disponíveis',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
                
                const SizedBox(height: 16),
                
                // Grid de usuários
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _exampleUsers.length,
                  itemBuilder: (context, index) {
                    final user = _exampleUsers[index];
                    final isSelected = _selectedAvatar == user['avatar'];
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAvatar = user['avatar']!;
                          _nameController.text = user['name']!;
                          _emailController.text = user['email']!;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected 
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Avatar
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected 
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: user['avatar']!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey.shade300,
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey.shade300,
                                    child: Icon(
                                      Icons.error,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Nome
                            Text(
                              user['name']!.split(' ').first,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            if (isSelected) ...[
                              const SizedBox(height: 4),
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ],
                        ),
                      ).animate(delay: (600 + index * 100).ms)
                        .fadeIn()
                        .slideY(begin: 0.3),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Campos de entrada
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, insira seu nome';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),
                
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, insira seu email';
                    }
                    if (!value.contains('@')) {
                      return 'Por favor, insira um email válido';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.3),
                
                const SizedBox(height: 32),
                
                // Botão de login
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : const Text('Entrar no Chat'),
                ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.3),
                
                const SizedBox(height: 16),
                
                // Status da conexão
                Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    if (chatProvider.error != null) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                          ),
                        ),
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
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: 0.3);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
