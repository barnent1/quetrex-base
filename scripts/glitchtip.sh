#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.glitchtip.yml"

case "$1" in
  start)
    echo "Starting GlitchTip..."
    docker compose -f "$COMPOSE_FILE" up -d
    echo ""
    echo "GlitchTip is starting at http://localhost:8000"
    echo ""
    echo "First time setup:"
    echo "  1. Wait ~30 seconds for services to initialize"
    echo "  2. Open http://localhost:8000/register"
    echo "  3. Create an account"
    echo "  4. Create a new organization and project"
    echo "  5. Copy the DSN and add to .env.local:"
    echo "     NEXT_PUBLIC_GLITCHTIP_DSN=http://YOUR_KEY@localhost:8000/1"
    ;;
  stop)
    echo "Stopping GlitchTip..."
    docker compose -f "$COMPOSE_FILE" down
    echo "GlitchTip stopped."
    ;;
  logs)
    docker compose -f "$COMPOSE_FILE" logs -f "${@:2}"
    ;;
  status)
    docker compose -f "$COMPOSE_FILE" ps
    ;;
  reset)
    echo "WARNING: This will delete all GlitchTip data!"
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      docker compose -f "$COMPOSE_FILE" down -v
      echo "GlitchTip reset complete. Run './scripts/glitchtip.sh start' to start fresh."
    else
      echo "Reset cancelled."
    fi
    ;;
  *)
    echo "GlitchTip Management Script"
    echo ""
    echo "Usage: $0 {command}"
    echo ""
    echo "Commands:"
    echo "  start   - Start GlitchTip services"
    echo "  stop    - Stop GlitchTip services"
    echo "  logs    - View logs (optional: service name)"
    echo "  status  - Show service status"
    echo "  reset   - Remove all data and start fresh"
    exit 1
    ;;
esac
