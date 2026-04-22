#!/usr/bin/env bash
set -e

CONFIG_DIR="/root/.hermes"
CONFIG_FILE="$CONFIG_DIR/config.toml"

mkdir -p "$CONFIG_DIR"

# Always rewrite config from env vars so env changes take effect on restart.
# Adjust key names if `hermes setup` produces a different schema — inspect
# ~/.hermes/config.toml after a manual `hermes setup` to confirm.
cat >"$CONFIG_FILE" <<EOF
[provider]
name = "openrouter"
api_key = "${OPENROUTER_API_KEY}"
model = "${HERMES_MODEL:-openrouter/free}"
EOF

# Browser Harness key
if [ -n "${BROWSER_USE_API_KEY}" ]; then
	hermes config set BROWSER_USE_API_KEY "${BROWSER_USE_API_KEY}" || true
fi

exec "$@"
