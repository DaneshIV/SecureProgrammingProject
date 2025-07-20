#!/bin/bash

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

# Set environment to local
./set-environment.sh local

# Validate configuration
echo "📄 Validating configuration..."
./validate-config.sh local

# Start the server
echo "🚀 Starting the server in local mode..."
echo "🌐 The application will be available at http://localhost:3000"
node server.js
