#!/bin/bash
# Start both Angular dev server and Express backend

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Starting Express server on https://localhost:3443..."
cd "$SCRIPT_DIR/server"
node index.js &
SERVER_PID=$!

echo "Starting Angular dev server on https://localhost:4300..."
cd "$SCRIPT_DIR/client"
npx ng serve &
CLIENT_PID=$!

trap "kill $SERVER_PID $CLIENT_PID 2>/dev/null" EXIT

echo ""
echo "Both servers starting:"
echo "  Frontend: https://localhost:4300"
echo "  Backend:  https://localhost:3443"
echo ""
echo "Press Ctrl+C to stop both."

wait
