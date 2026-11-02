#!/bin/bash
# 02_install_mcp.sh
# Запускать на Kali с правами sudo
# Предполагается, что часть 1 уже выполнена и Ollama работает.

set -e

echo "=== 1. Принудительная установка Flask и mcp-kali-server ==="
sudo apt update
sudo apt install -y python3-flask
sudo apt install --reinstall -y mcp-kali-server nmap gobuster nikto dirb python3-pip python3-venv

echo "=== 2. Проверка, что Flask импортируется системным Python ==="
if ! python3 -c "import flask" 2>/dev/null; then
    echo "❌ Flask не импортируется. Диагностика:"
    dpkg -l | grep python3-flask || true
    echo "Попробуйте: sudo apt install --reinstall python3-flask"
    exit 1
fi
echo "✅ Flask импортируется."

echo "=== 3. Установка ollmcp в venv ==="
VENV="$HOME/ollmcp-venv"
if [ ! -d "$VENV" ]; then
    python3 -m venv "$VENV"
fi
source "$VENV/bin/activate"
pip install --upgrade pip
pip install ollmcp

# JSON-конфиг для ollmcp
cat > ~/kali-mcp.json << 'EOF'
{
  "mcpServers": {
    "kali": {
      "command": "/usr/bin/mcp-server",
      "args": ["--server", "http://127.0.0.1:5000"]
    }
  }
}
EOF
echo "✅ Создан конфиг: ~/kali-mcp.json"

echo "=== 4. Запуск API-сервера Kali ==="
pkill -f kali-server-mcp 2>/dev/null || true
sleep 1

nohup kali-server-mcp --ip 127.0.0.1 --port 5000 > ~/kali_api.log 2>&1 &
API_PID=$!
echo "API-сервер запущен (PID: $API_PID)"
sleep 3

if ! kill -0 $API_PID 2>/dev/null; then
    echo "❌ API-сервер упал. Лог:"
    cat ~/kali_api.log
    exit 1
fi

echo "=== 5. Проверка /health ==="
HEALTH=$(curl -s http://127.0.0.1:5000/health)
echo "$HEALTH"

if echo "$HEALTH" | grep -q '"status":"healthy"'; then
    echo "✅ API-сервер работает."
else
    echo "❌ API-сервер не отвечает корректно. Лог:"
    cat ~/kali_api.log
    exit 1
fi

echo ""
echo "=== 6. Готово ==="
echo "Запустите ollmcp:"
echo "  source ~/ollmcp-venv/bin/activate"
echo "  ollmcp --servers-json ~/kali-mcp.json --model qwen2.5:7b"
echo ""
echo "В интерфейсе ollmcp: /rc (сброс конфига, включает все инструменты)."