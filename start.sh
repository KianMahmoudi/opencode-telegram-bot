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
      "options": { "baseURL": "${NINE_ROUTER_URL}" },
      "models": {
        "${OPENCODE_MODEL_ID}": { "name": "9Router model" }
      }
    }
  }
}
EOF
opencode serve --port 4096 &
exec node dist/index.js
