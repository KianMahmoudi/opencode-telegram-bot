#!/bin/sh
set -e
mkdir -p /home/node/.config/opencode
cat > /home/node/.config/opencode/opencode.json <<EOF
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "9router": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "9Router",
      "options": {
        "baseURL": "${NINE_ROUTER_URL}",
        "apiKey": "${NINE_ROUTER_API_KEY}"
      },
    "models": {
  "${OPENCODE_MODEL_ID}": {
    "name": "9Router model",
    "limit": {
      "context": 1000000,
      "output": 64000
    }
  }
}
    }
  }
}
EOF

opencode serve --port 4096 &

# Wait for opencode to be ready before starting the bot
for i in $(seq 1 60); do
  if wget -q -O /dev/null http://127.0.0.1:4096/ 2>/dev/null; then
    break
  fi
  sleep 1
done

exec node dist/index.js
