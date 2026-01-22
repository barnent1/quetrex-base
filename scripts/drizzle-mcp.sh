#!/bin/bash
# Load environment variables from .env.local
set -a
source "$(dirname "$0")/../.env.local" 2>/dev/null || true
set +a

# Run the drizzle MCP server
exec npx -y github:defrex/drizzle-mcp "$@"
