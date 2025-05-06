# === 建置階段 ===
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /src

# 1. 先複製三個 .csproj，並還原相依
# 注意：資料夾結尾有 ~，所以要加上反斜線或用引號確保路徑正確
COPY src/Promul/Promul.csproj          ./Promul/
COPY src/Promul.Relay.Protocol/Promul.Relay.Protocol.csproj  ./Promul.Relay.Protocol/
COPY src/Promul.Server~/Promul.Relay.Server.csproj           ./Promul.Server~/
RUN dotnet restore "./Promul.Server~/Promul.Relay.Server.csproj"

# 2. 複製剩下的原始碼
COPY src/. .

# 3. 發佈
RUN dotnet publish "./Promul.Server~/Promul.Relay.Server.csproj" \
    -c Release \
    -o /app/publish \
    --no-restore

# === 執行階段 ===
FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS runtime
WORKDIR /app

# 4. 從 build 階段複製發佈結果
COPY --from=build /app/publish ./

# 讓 Kestrel 監聽所有介面
ENV ASPNETCORE_URLS=http://0.0.0.0:3000

# 5. 開放埠號
EXPOSE 4098/udp
EXPOSE 3000/tcp

# 6. 啟動服務
ENTRYPOINT ["dotnet", "Promul.Relay.Server.dll"]
