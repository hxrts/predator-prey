#!/usr/bin/env bash

# Create necessary directories
mkdir -p public output/Main

# Helper function to show server information
show_server_info() {
  local port=$1
  local ip_addresses
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS command to get IP addresses
    ip_addresses=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}')
  else
    # Linux command to get IP addresses
    ip_addresses=$(ip addr show | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1)
  fi

  echo "Application available at:"
  echo "  http://127.0.0.1:${port}"
  for ip in $ip_addresses; do
    echo "  http://$ip:${port}"
  done
  echo "Hit CTRL-C to stop the server"
  echo ""
}

# Define the build-project command
build-project() {
  echo "Building PureScript project..."
  # Ensure src/Main.purs exists
  if [ ! -f src/Main.purs ]; then
    echo "Error: src/Main.purs not found!"
    return 1
  fi

  # Build PureScript code
  if ! spago build; then
    echo "Error: PureScript build failed!"
    return 1
  fi

  echo "Bundling JavaScript..."
  # Create a temporary entry point that properly imports the PureScript code
  echo 'import * as Main from "../output/Main/index.js";' > output/entry.js
  echo 'function main() { Main.main(); }' >> output/entry.js
  echo 'if (typeof window !== "undefined") { window.addEventListener("load", main); }' >> output/entry.js

  # Bundle JavaScript with the new entry point
  if ! esbuild output/entry.js --bundle --outfile=public/bundle.js --platform=browser; then
    echo "Error: JavaScript bundling failed!"
    return 1
  fi

  # Clean up temporary entry point
  rm output/entry.js

  echo "Build complete! Run 'serve-project' to serve the application"
}

# Define a quiet version of build-project
build-project-quiet() {
  # Ensure src/Main.purs exists
  if [ ! -f src/Main.purs ]; then
    return 1
  fi

  # Build PureScript code
  if ! spago build > /dev/null 2>&1; then
    return 1
  fi

  # Create a temporary entry point that properly imports the PureScript code
  echo 'import * as Main from "../output/Main/index.js";' > output/entry.js
  echo 'function main() { Main.main(); }' >> output/entry.js
  echo 'if (typeof window !== "undefined") { window.addEventListener("load", main); }' >> output/entry.js

  # Bundle JavaScript with the new entry point
  if ! esbuild output/entry.js --bundle --outfile=public/bundle.js --platform=browser > /dev/null 2>&1; then
    return 1
  fi

  # Clean up temporary entry point
  rm output/entry.js

  return 0
}

# Define the serve-project command
serve-project() {
  echo "Starting development server..."
  
  # Check if bundle exists
  if [ ! -f public/bundle.js ]; then
    echo "Bundle not found. Running build-project first..."
    if ! build-project; then
      echo "Error: Failed to build project. Please fix the errors and try again."
      return 1
    fi
  fi

  # Debug info
  echo "Serving files from public directory..."
  echo "Bundle location: $(pwd)/public/bundle.js"
  echo "Files in public directory:"
  ls public/
  echo ""

  # Kill any existing http-server processes
  pkill -f "http-server.*public"

  # Check if port 8080 is available
  if ! lsof -i:8080 >/dev/null 2>&1; then
    port=8080
  else
    port=8081
  fi

  # Show server information
  show_server_info "$port"

  # Start server from public directory with the selected port
  http-server public -c-1 -p "$port"
}

# Define the watch-project command
watch-project() {
  echo "Starting watch mode..."
  echo "Running initial build..."
  
  # Do initial build with full output
  if ! build-project; then
    echo "Initial build failed. Watching for changes..."
    return 1
  fi

  echo "Initial build successful!"
  echo ""

  # Kill any existing http-server processes
  pkill -f "http-server.*public"

  # Check if port 8080 is available
  if ! lsof -i:8080 >/dev/null 2>&1; then
    port=8080
  else
    port=8081
  fi

  # Show server information
  show_server_info "$port"
  echo "Watching for changes..."

  # Start server in background
  http-server public -c-1 -p "$port" &
  server_pid=$!

  # Set up trap to clean up server on script exit
  trap "kill $server_pid 2>/dev/null" EXIT

  # Watch for changes
  while true; do
    if inotifywait -q -r -e modify src/ > /dev/null 2>&1; then
      echo "Changes detected, rebuilding..."
      if build-project-quiet; then
        echo "Build successful! ($(date '+%H:%M:%S'))"
      else
        # If quiet build fails, run full build for error output
        build-project
        echo "Build failed. Waiting for changes..."
      fi
    fi
  done
}

# Export the functions
export -f build-project
export -f build-project-quiet
export -f serve-project
export -f watch-project
export -f show_server_info

# Print available commands
echo "Available commands:"
echo "  build-project  - Build and bundle the PureScript application"
echo "  serve-project  - Serve the application locally"
echo "  watch-project  - Watch for changes and rebuild automatically"
echo ""

# Initial setup check
if [ ! -f src/Main.purs ]; then
  echo "Warning: src/Main.purs not found. Please ensure your PureScript source files are in place."
fi 