#!/usr/bin/env bash
set -e

trap 'kill 0' EXIT

cd /app/server
PORT=3000 node index.js &

for i in {1..30}; do
  if curl -sf http://localhost:3000/openapi.json > /dev/null 2>&1; then
    echo "API ready"
    break
  fi
  sleep 1
done

cd /app/cobol
export API_BASE_URL="http://localhost:3000"
./cobol-admin &

wait -n
exit $?
