#!/bin/bash

# Use the existing ngrok URL
NGROK_URL="https://83bc16e00594.ngrok-free.app"

# Check if port 3000 is already in use
if lsof -i:3000 >/dev/null 2>&1; then
  echo "⚠️  Port 3000 is already in use. Stopping existing processes..."
  # Get PIDs of processes using port 3000
  PIDS=$(lsof -t -i:3000)
  if [ ! -z "$PIDS" ]; then
    echo "Stopping processes: $PIDS"
    kill -9 $PIDS
    sleep 1
  fi
fi

echo "🔧 Setting up environment for existing ngrok URL:"
echo "📡 URL: $NGROK_URL"

# Set the environment configuration
./set-environment.sh ngrok "$NGROK_URL"

# Start the server
echo "🚀 Starting the Node.js server..."
node server.js
