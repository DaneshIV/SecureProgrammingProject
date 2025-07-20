# Development Configuration Helper

# This file is loaded by environment-specific scripts to configure the application
# Set variables here based on environment (local, ngrok, etc.)

# Function to set the environment
set_environment() {
  local env=$1
  local api_url=$2
  
  echo "Setting environment to: $env"
  echo "API URL: $api_url"
  
  cat > ./public/config.js << EOF
// Auto-generated config file - Do not edit manually
window.APP_CONFIG = {
  API_URL: "$api_url",
  ENVIRONMENT: "$env"
};
EOF

  echo "Configuration updated successfully!"
}

# Used by other scripts to set environment
if [ "$1" = "local" ]; then
  set_environment "local" ""
elif [ "$1" = "ngrok" ]; then
  # Get the ngrok URL from environment or prompt
  if [ -z "$2" ]; then
    read -p "Enter your ngrok URL (e.g., https://abc123.ngrok-free.app): " NGROK_URL
  else
    NGROK_URL=$2
  fi
  
  set_environment "ngrok" "$NGROK_URL"
else
  echo "Usage: $0 [local|ngrok] [ngrok_url]"
  exit 1
fi
