# Use the official .NET 9 runtime image
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 5000

# Use the official .NET 9 SDK image for building
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy the project file and restore dependencies
COPY ["ChatServer/SignalRChatServer/SignalRChatServer.csproj", "ChatServer/SignalRChatServer/"]
RUN dotnet restore "ChatServer/SignalRChatServer/SignalRChatServer.csproj"

# Copy the rest of the source code
COPY . .
WORKDIR "/src/ChatServer/SignalRChatServer"

# Build the application
RUN dotnet build "SignalRChatServer.csproj" -c Release -o /app/build

# Publish the application
FROM build AS publish
RUN dotnet publish "SignalRChatServer.csproj" -c Release -o /app/publish

# Build the final runtime image
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Set environment variables
ENV ASPNETCORE_URLS=http://+:5000
ENV ASPNETCORE_ENVIRONMENT=Production

# Run the application
ENTRYPOINT ["dotnet", "SignalRChatServer.dll"]
