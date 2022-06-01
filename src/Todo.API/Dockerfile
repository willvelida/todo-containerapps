FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src
COPY ["Todo.API/Todo.API.csproj", "Todo.API/"]
RUN dotnet restore "Todo.API/Todo.API.csproj"
COPY . .
WORKDIR "/src/Todo.API"
RUN dotnet build "Todo.API.csproj" -c Release -o /app

FROM build AS publish
RUN dotnet publish "Todo.API.csproj" -c Release -o /app

FROM base AS final
WORKDIR /app
COPY --from=publish /app .
ENTRYPOINT [ "dotnet", "Todo.API.dll" ]