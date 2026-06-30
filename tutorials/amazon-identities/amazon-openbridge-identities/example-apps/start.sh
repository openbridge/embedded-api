#!/bin/bash

trap 'kill 0' EXIT

echo "Starting backend on :3000..."
cd backend && npm start &

echo "Starting frontend on :4300 (SSL)..."
cd frontend && ng serve --port 4300 --ssl &

wait
