#!/bin/bash

echo "🚀 Iniciando SignalR Ultra Chat Example (.NET 9)"
echo "=================================================="

# Verificar se o Flutter está instalado
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter não encontrado. Por favor, instale o Flutter primeiro."
    exit 1
fi

# Verificar se o .NET está instalado
if ! command -v dotnet &> /dev/null; then
    echo "❌ .NET não encontrado. Por favor, instale o .NET 9 primeiro."
    exit 1
fi

# Verificar versão do .NET
NET_VERSION=$(dotnet --version)
echo "✅ Flutter e .NET $NET_VERSION encontrados"

# Navegar para o diretório do exemplo
cd "$(dirname "$0")"

# Perguntar se quer usar Docker
echo ""
echo "🐳 Deseja usar Docker para o servidor? (y/n)"
read -r use_docker

if [[ $use_docker =~ ^[Yy]$ ]]; then
    echo ""
    echo "🐳 Verificando Docker..."
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker não encontrado. Usando .NET local."
        use_docker=false
    else
        echo "✅ Docker encontrado"
    fi
fi

echo ""
echo "📦 Instalando dependências Flutter..."
flutter pub get

echo ""
echo "🔧 Gerando código Hive..."
flutter packages pub run build_runner build --delete-conflicting-outputs

if [[ $use_docker =~ ^[Yy]$ ]]; then
    echo ""
    echo "🐳 Construindo imagem Docker..."
    docker build -t signalr-chat-server .
    
    echo ""
    echo "🐳 Iniciando servidor Docker..."
    echo "O servidor estará disponível em: http://localhost:5000"
    echo "Endpoints disponíveis:"
    echo "  - /api/status - Status do servidor"
    echo "  - /api/health - Saúde do sistema"
    echo "  - /chatHub - Hub principal do chat"
    echo "  - /notificationHub - Hub de notificações"
    echo ""
    echo "Pressione Ctrl+C para parar o servidor"
    echo ""
    
    # Iniciar o servidor Docker em background
    docker run -p 5000:5000 signalr-chat-server &
    DOCKER_PID=$!
    
    # Aguardar um pouco para o servidor inicializar
    sleep 5
else
    echo ""
    echo "🏗️ Restaurando dependências .NET 9..."
    cd ChatServer/SignalRChatServer
    dotnet restore
    
    echo ""
    echo "🔨 Compilando projeto .NET 9..."
    dotnet build
    
    echo ""
    echo "🚀 Iniciando servidor .NET 9..."
    echo "O servidor estará disponível em: http://localhost:5000"
    echo "Endpoints disponíveis:"
    echo "  - /api/status - Status do servidor"
    echo "  - /api/health - Saúde do sistema"
    echo "  - /chatHub - Hub principal do chat"
    echo "  - /notificationHub - Hub de notificações"
    echo ""
    echo "Pressione Ctrl+C para parar o servidor"
    echo ""
    
    # Iniciar o servidor em background
    dotnet run &
    DOTNET_PID=$!
    
    # Aguardar um pouco para o servidor inicializar
    sleep 3
    
    # Voltar para o diretório do exemplo
    cd ../..
fi

echo ""
echo "📱 Iniciando aplicativo Flutter..."
echo "Pressione Ctrl+C para parar o aplicativo"
echo ""

# Iniciar o Flutter
flutter run

# Quando o Flutter parar, parar também o servidor
echo ""
echo "🛑 Parando servidor..."

if [[ $use_docker =~ ^[Yy]$ ]]; then
    docker stop $(docker ps -q --filter ancestor=signalr-chat-server)
    docker rm $(docker ps -aq --filter ancestor=signalr-chat-server)
else
    kill $DOTNET_PID 2>/dev/null || true
fi

echo ""
echo "✅ Exemplo finalizado!"
