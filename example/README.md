# 🚀 SignalR Ultra Chat - Exemplo Impressionante (.NET 9)

Um exemplo completo e moderno de chat em tempo real usando **SignalR Ultra** com Flutter e **.NET 9**.

## ✨ Características

### 🎨 **Interface Moderna**
- Design Material 3 com tema claro/escuro
- Animações suaves e responsivas
- UI/UX profissional e intuitiva
- Suporte a modo escuro automático

### 💬 **Funcionalidades Avançadas**
- **Chat em tempo real** com SignalR
- **Múltiplas salas** de conversa
- **Indicador de digitação** em tempo real
- **Status de usuários** (online, ausente, ocupado, offline)
- **Edição e exclusão** de mensagens
- **Sistema de reações** às mensagens
- **Resposta a mensagens** específicas
- **Histórico de mensagens** persistente
- **Notificações** em tempo real

### 🔧 **Tecnologias Utilizadas**

#### **Backend (.NET 9)**
- ASP.NET Core 9
- SignalR para comunicação em tempo real
- Arquitetura limpa com serviços
- Logging avançado
- CORS configurado
- Endpoints de saúde e status

#### **Frontend (Flutter)**
- Flutter 3.x com Dart 3
- Provider para gerenciamento de estado
- Hive para armazenamento local
- Animações com flutter_animate
- Cache de imagens com cached_network_image
- UI responsiva e moderna

## 🏗️ **Arquitetura**

### **Backend Structure**
```
ChatServer/
├── SignalRChatServer/
│   ├── Models/
│   │   ├── ChatMessage.cs
│   │   ├── User.cs
│   │   └── ChatRoom.cs
│   ├── Services/
│   │   ├── ChatService.cs
│   │   └── UserService.cs
│   ├── Hubs/
│   │   ├── ChatHub.cs
│   │   └── NotificationHub.cs
│   └── Program.cs
```

### **Frontend Structure**
```
lib/
├── models/
│   ├── chat_message.dart
│   ├── user.dart
│   └── chat_room.dart
├── providers/
│   └── chat_provider.dart
├── screens/
│   ├── login_screen.dart
│   ├── rooms_screen.dart
│   └── chat_screen.dart
├── widgets/
│   ├── message_bubble.dart
│   └── typing_indicator.dart
├── services/
│   └── chat_service.dart
├── utils/
│   └── theme.dart
└── main.dart
```

## 🚀 **Como Executar**

### **Opção 1: Script Automático (Recomendado)**
```bash
cd example
./run_example.sh
```

### **Opção 2: Manual**

#### **1. Backend (.NET 9)**
```bash
cd example/ChatServer/SignalRChatServer
dotnet restore
dotnet build
dotnet run
```

O servidor estará disponível em: `http://localhost:5000`

#### **2. Frontend (Flutter)**
```bash
cd example
flutter pub get
flutter packages pub run build_runner build --delete-conflicting-outputs
flutter run
```

## 📱 **Funcionalidades Demonstradas**

### **Tela de Login**
- Seleção de usuários pré-configurados
- Validação de formulário
- Animações de entrada
- Status de conexão em tempo real

### **Tela de Salas**
- Lista de salas disponíveis
- Criação de novas salas
- Lista de usuários online
- Indicadores de status
- Navegação intuitiva

### **Tela de Chat**
- Mensagens em tempo real
- Indicador de digitação
- Edição e exclusão de mensagens
- Sistema de reações
- Resposta a mensagens
- Status de entrega
- Scroll automático

## 🎯 **Recursos Técnicos**

### **SignalR Ultra Features**
- ✅ Conexão WebSocket automática
- ✅ Fallback para Long Polling
- ✅ Reconexão automática
- ✅ Logging detalhado
- ✅ Gerenciamento de estado
- ✅ Tratamento de erros

### **Flutter Features**
- ✅ Provider para estado global
- ✅ Hive para persistência local
- ✅ Animações fluidas
- ✅ UI responsiva
- ✅ Tema dinâmico
- ✅ Cache de imagens

### **Backend Features (.NET 9)**
- ✅ Hub de chat principal
- ✅ Hub de notificações
- ✅ Serviços modulares
- ✅ Modelos tipados
- ✅ Logging estruturado
- ✅ CORS configurado
- ✅ Endpoints de saúde
- ✅ Configurações otimizadas

## 🔧 **Configuração**

### **Variáveis de Ambiente**
```bash
# Backend
ASPNETCORE_ENVIRONMENT=Development
ASPNETCORE_URLS=http://localhost:5000

# Frontend
CHAT_SERVER_URL=http://localhost:5000
```

### **Dependências**

#### **Backend (.NET 9)**
```xml
<PackageReference Include="Microsoft.AspNetCore.SignalR" Version="1.1.0" />
<PackageReference Include="Microsoft.AspNetCore.SignalR.Client" Version="9.0.0" />
<PackageReference Include="Swashbuckle.AspNetCore" Version="7.0.0" />
```

#### **Frontend (Flutter)**
```yaml
dependencies:
  signalr_ultra: ^1.0.0
  provider: ^6.1.2
  flutter_animate: ^4.5.0
  cached_network_image: ^3.3.1
  hive: ^2.2.3
  rxdart: ^0.28.0
```

## 📊 **Performance (.NET 9)**

- **Latência**: < 100ms para mensagens
- **Reconexão**: Automática em 3 segundos
- **Cache**: Imagens e dados locais
- **Memória**: Otimizada para dispositivos móveis
- **Compilação**: AOT para melhor performance
- **GC**: Otimizações do .NET 9

## 🛠️ **Desenvolvimento**

### **Estrutura de Dados**

#### **ChatMessage**
```dart
class ChatMessage {
  String id;
  String content;
  String senderId;
  String senderName;
  String senderAvatar;
  DateTime timestamp;
  MessageType type;
  MessageStatus status;
  List<String> reactions;
  bool isEdited;
  ChatMessage? replyToMessage;
}
```

#### **User**
```dart
class User {
  String id;
  String name;
  String email;
  String avatar;
  UserStatus status;
  DateTime lastSeen;
  List<String> connectedRooms;
}
```

#### **ChatRoom**
```dart
class ChatRoom {
  String id;
  String name;
  String description;
  RoomType type;
  List<String> members;
  List<String> admins;
  DateTime createdAt;
  ChatMessage? lastMessage;
}
```

## 🎨 **Temas e Estilo**

### **Cores Principais**
- **Primary**: `#6366F1` (Indigo)
- **Secondary**: `#8B5CF6` (Purple)
- **Accent**: `#06B6D4` (Cyan)
- **Success**: `#10B981` (Emerald)
- **Warning**: `#F59E0B` (Amber)
- **Error**: `#EF4444` (Red)

### **Tipografia**
- **Família**: Inter
- **Pesos**: Regular, Medium, SemiBold, Bold
- **Responsiva**: Adaptável a diferentes tamanhos de tela

## 🔒 **Segurança**

- Validação de entrada no backend
- Sanitização de dados
- CORS configurado adequadamente
- Logging de eventos de segurança
- Timeouts configurados

## 📈 **Monitoramento**

- Logs estruturados
- Métricas de performance
- Status de conexão em tempo real
- Tratamento de erros robusto
- Endpoints de saúde
- Monitoramento de memória

## 🆕 **Novidades do .NET 9**

- **Performance melhorada**: AOT compilation
- **GC otimizado**: Melhor gerenciamento de memória
- **Logging avançado**: Structured logging
- **Configurações flexíveis**: Timeouts e keep-alive
- **Endpoints de saúde**: Monitoramento integrado

## 🤝 **Contribuição**

1. Fork o projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📄 **Licença**

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](../LICENSE) para mais detalhes.

## 🙏 **Agradecimentos**

- **SignalR Team** pela tecnologia incrível
- **Flutter Team** pelo framework fantástico
- **.NET Team** pelas melhorias do .NET 9
- **Comunidade** pelo suporte e feedback

---

**Desenvolvido com ❤️ usando SignalR Ultra e .NET 9**
