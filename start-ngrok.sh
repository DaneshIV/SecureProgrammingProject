#!/bin/bash

# Check if ngrok is installed
if ! command -v ngrok &> /dev/null; then
    echo "ngrok is not installed. Please install it first."
    echo "Visit https://ngrok.com/download for installation instructions."
    exit 1
fi

# Start ngrok in the background and get the URL
echo "Starting ngrok tunnel to port 3000..."
ngrok http 3000 > ngrok.log 2>&1 &
NGROK_PID=$!

# Wait for ngrok to generate a URL (timeout after 10 seconds)
MAX_ATTEMPTS=20
ATTEMPT=0
NGROK_URL=""

echo "Waiting for ngrok to generate URL..."
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT+1))
    sleep 0.5
    
    if grep -q "url=https" ngrok.log; then
        NGROK_URL=$(grep -o 'url=https://[^ ]*' ngrok.log | sed 's/url=//')
        break
    fi
done

if [ -z "$NGROK_URL" ]; then
    echo "Failed to get ngrok URL after 10 seconds."
    kill $NGROK_PID
    rm ngrok.log
    exit 1
fi

echo "✅ Ngrok URL: $NGROK_URL"

# Set the environment configuration
./set-environment.sh ngrok "$NGROK_URL"

# Start the server
echo "Starting the Node.js server..."
node server.js

# When server is terminated, also terminate ngrok
kill $NGROK_PID
rm ngrok.log
echo "Ngrok tunnel stopped."
