FROM mcr.microsoft.com/dotnet/aspnet:9.0-alpine AS base
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
ENV DOTNET_gcServer=0
ENV DOTNET_GCHeapHardLimit=0x10000000

FROM mcr.microsoft.com/dotnet/sdk:9.0-alpine AS build
WORKDIR /src
COPY ["development.csproj", "."]
RUN dotnet restore --runtime linux-musl-x64
COPY . .
RUN dotnet publish -c Release -o /app/publish --runtime linux-musl-x64 --self-contained false /p:PublishTrimmed=false

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "development.dll"]
