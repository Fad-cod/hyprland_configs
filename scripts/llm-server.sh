#!/usr/bin/env bash
# ── llama-server launcher ─────────────────────────────────────
# Usage: llm-server [start|stop|status] [model]
#
# Models: qwen (default, 1.5B), gemma (2B)
# ─────────────────────────────────────────────────────────────

set -euo pipefail

MODEL_DIR="$HOME/llama-models"
PORT="${LLM_PORT:-8080}"
HOST="${LLM_HOST:-127.0.0.1}"

# ── Prerequisites ────────────────────────────────────────────
for cmd in curl llama-server; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "❌ $cmd n'est pas installé ou pas dans le PATH."
    echo "   Ajoutez d'abord llama.cpp au PATH : export PATH=\"\$HOME/llama.cpp/build/bin:\$PATH\""
    exit 1
  fi
done

# ── Vulkan check ────────────────────────────────────────────
check_vulkan() {
  if ! vulkaninfo --summary &>/dev/null; then
    echo "⚠️  Vulkan semble indisponible. Continuons sans accélération GPU."
    echo "   Pour info : lancez 'vulkaninfo --summary' pour le diagnostic."
  fi
}

# ── Vérification du processus llama-server ──────────────────
# Utilise pgrep/pkill (fiable, disponible partout) au lieu de ss
llama_pids() {
  pgrep -f "llama-server.*$PORT" 2>/dev/null || true
}

server_running() {
  [ -n "$(llama_pids)" ]
}

# ── Model selection ──────────────────────────────────────────
select_model() {
  case "${1:-qwen}" in
    qwen)
      MODEL="$MODEL_DIR/qwen2.5-coder-1.5b.Q4_K_M.gguf"
      NAME="qwen2.5-coder-1.5b"
      ;;
    gemma)
      MODEL="$MODEL_DIR/gemma2-2b.gguf"
      NAME="gemma2-2b"
      ;;
    *)
      echo "❌ Modèle inconnu : $1. Utilisez : qwen, gemma"
      exit 1
      ;;
  esac

  if [ ! -f "$MODEL" ]; then
    echo "❌ Fichier modèle introuvable : $MODEL"
    exit 1
  fi
}

# ── Commands ─────────────────────────────────────────────────
start() {
  select_model "${1:-qwen}"
  check_vulkan

  if server_running; then
    echo "⚠️  Un serveur tourne déjà sur le port $PORT"
    echo "   PID : $(llama_pids | head -1)"
    echo "   Utilisez 'llm-server stop' puis relancez."
    exit 1
  fi

  echo "🚀 Démarrage de llama-server — $NAME (Vulkan GPU)"
  echo "   Modèle : $MODEL"
  echo "   Port   : $HOST:$PORT"
  echo "   GPU    : $(vulkaninfo --summary 2>/dev/null | grep deviceName | head -1 || echo 'Vulkan OK')"
  echo ""
  echo "   📡 Serveur API OpenAI-compatible : http://$HOST:$PORT/v1"
  echo "   📋 Logs : ~/.local/share/llama-server.log"
  echo ""

  nohup llama-server \
    -m "$MODEL" \
    -ngl 99 \
    --mlock \
    --host "$HOST" \
    --port "$PORT" \
    --ctx-size 4096 \
    --temp 0.7 \
    --repeat-penalty 1.1 \
    --log-file "$HOME/.local/share/llama-server.log" \
    --log-timestamps \
    &>/dev/null &

  PID=$!
  echo "✓ PID : $PID"
  echo ""
  
  # Attendre que le serveur soit prêt (timeout 90s pour GPU modeste)
  echo -n "⏳ Chargement du modèle sur GPU Vulkan..."
  for i in $(seq 1 90); do
    # Vérifier que le processus est toujours vivant
    if ! kill -0 "$PID" 2>/dev/null; then
      echo ""
      echo "❌ Le processus s'est arrêté prématurément."
      echo "   Vérifiez les logs : tail -50 $HOME/.local/share/llama-server.log"
      return 1
    fi
    # Vérifier que l'API répond avec un code 200 (pas 503 Loading)
    HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 2 "http://$HOST:$PORT/v1/models" 2>/dev/null)
    if [ "$HTTP_CODE" = "200" ]; then
      echo ""
      echo "✅ Serveur prêt !"
      echo ""
      echo "   ▶️  Utilisez OpenCode avec le provider 'llama-local'"
      echo "   ▶  Test : curl http://$HOST:$PORT/v1/models"
      return 0
    fi
    echo -n "."
    sleep 1
  done

  echo ""
  echo "⚠️  Délai d'attente dépassé (90s). Le modèle est peut-être trop gros pour le GPU."
  echo "   Vérifiez les logs : tail -50 $HOME/.local/share/llama-server.log"
  echo ""
  echo "   💡 Conseil : Essayez avec -ngl 50 (moins de couches GPU)"
  return 1
}

stop() {
  PIDS=$(llama_pids)
  if [ -n "$PIDS" ]; then
    echo "🛑 Arrêt du serveur (PID $PIDS)..."
    kill $PIDS 2>/dev/null
    sleep 2
    if server_running; then
      echo "   Résiste... force l'arrêt"
      kill -9 $PIDS 2>/dev/null
      sleep 1
    fi
    if server_running; then
      echo "⚠️  Impossible d'arrêter le processus manuellement"
    else
      echo "✓ Serveur arrêté"
    fi
  else
    echo "ℹ️  Aucun serveur sur le port $PORT"
  fi
}

status() {
  echo "📊 Statut du serveur llama-server :"
  echo ""
  if server_running; then
    PIDS=$(llama_pids)
    echo "   ✅ En cours d'exécution"
    echo "   PID   : $PIDS"
    echo "   Port  : $PORT"
    FIRST_PID=$(echo $PIDS | awk '{print $1}')
    echo "   Modèle: $(ps -p $FIRST_PID -o args= 2>/dev/null | grep -oP '(?<=-m )\S+' || echo 'N/A')"
    echo ""
    HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 "http://$HOST:$PORT/v1/models" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
      echo "   ✅ API répond (HTTP 200) sur http://$HOST:$PORT/v1"
    elif [ "$HTTP_CODE" = "503" ]; then
      echo "   ⏳ API répond 503 — modèle en cours de chargement"
    else
      echo "   ⚠️  API ne répond pas (HTTP $HTTP_CODE)"
    fi
  else
    echo "   ❌ Aucun serveur en cours"
    echo ""
    echo "   ▶️  Lancez : llm-server start [qwen|gemma]"
  fi
}

# ── Main ─────────────────────────────────────────────────────
mkdir -p "$HOME/.local/share"

case "${1:-status}" in
  start)
    start "${2:-qwen}"
    ;;
  stop)
    stop
    ;;
  restart)
    stop
    sleep 1
    start "${2:-qwen}"
    ;;
  status)
    status
    ;;
  *)
    echo "Usage: llm-server [start|stop|restart|status] [qwen|gemma]"
    exit 1
    ;;
esac
