#!/bin/bash

set -e  # Exit on error

# --- Check if Docker is running ---
if ! docker info >/dev/null 2>&1; then
  echo "❌ Docker is not running. Please start Docker and try again."
  exit 1
else
  echo "✅ Docker is running."
fi

# --- Function to check if a port is free ---
check_port_free() {
  local port=$1
  if lsof -i :"$port" >/dev/null 2>&1; then
    echo "❌ Port $port is currently in use. Please free it before continuing."
    exit 1
  else
    echo "✅ Port $port is free."
  fi
}

# --- Check required ports ---
check_port_free 5173
check_port_free 9000

# --- Move into frontend directory ---
if [ -d "./frontend" ]; then
  cd ./frontend || exit 1
  echo "📂 Changed directory to ./frontend."
else
  echo "❌ Directory ./frontend not found."
  exit 1
fi

# --- Handle .env file creation ---
if [ -f ".env" ]; then
  echo "ℹ️  .env already exists. Skipping setup environment"
elif [ -f ".env.template" ]; then
  mv .env.template .env
  echo "✅ Renamed .env.template to .env."
else
  echo "⚠️  No .env or .env.template file found."
fi

# --- Go back to project root ---
cd .. || exit 1
echo "📂 Returned to project root."

# --- Detect docker compose command ---
if command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD="docker compose"
else
  echo "❌ Neither 'docker-compose' nor 'docker compose' is available."
  exit 1
fi

echo "🧩 Using '$COMPOSE_CMD' to start containers."

# --- Run docker compose ---
echo "🚀 Starting Docker containers..."
$COMPOSE_CMD up --build
