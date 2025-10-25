FROM mcr.microsoft.com/dotnet/sdk:9.0
WORKDIR /app

# Copy project files
COPY ["src/EventCalendar/EventCalendar.csproj", "./"]
RUN dotnet restore

# Copy the rest of the code
COPY ["src/EventCalendar", "./"]

EXPOSE 9000
ENV ASPNETCORE_URLS=http://+:9000

# Use watch for auto-reload on code changes
CMD ["dotnet", "watch", "run", "--urls", "http://+:9000"]

