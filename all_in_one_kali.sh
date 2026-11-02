#!/bin/bash
# all_in_one_kali.sh (v2, с явной установкой Flask и проверкой)
# Запускать на Kali с правами sudo

set -e

echo "=== 1. Установка Ollama ==="
if ! command -v ollama &> /dev/null; then
    curl -fsSL https://ollama.com/install.sh | sh
    sudo systemctl enable --now ollama
    sleep 2
fi
ollama --version

echo "=== 2. Загрузка модели qwen2.5:7b ==="
ollama pull qwen2.5:7b

echo "=== 3. Установка mcp-kali-server, инструментов и ЗАВИСИМОСТЕЙ ==="
sudo apt update
# Явно ставим python3-flask, чтобы не полагаться только на зависимости пакета
sudo apt install -y mcp-kali-server python3-flask nmap gobuster nikto dirb python3-pip python3-venv

echo "=== 4. Установка ollmcp в venv ==="
VENV="$HOME/ollmcp-venv"
if [ ! -d "$VENV" ]; then
    python3 -m venv "$VENV"
fi
source "$VENV/bin/activate"
pip install --upgrade pip
pip install ollmcp

# Создаём JSON-конфиг для ollmcp (чтобы не мучиться с --mcp-server)
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
echo "Создан конфиг: ~/kali-mcp.json"

echo "=== 5. Запуск API-сервера Kali (порт 5000, только localhost) ==="
pkill -f kali-server-mcp 2>/dev/null || true
sleep 1

# Запускаем и проверяем, что процесс не упал сразу
nohup kali-server-mcp --ip 127.0.0.1 --port 5000 > ~/kali_api.log 2>&1 &
API_PID=$!
echo "API-сервер запущен (PID: $API_PID)"
sleep 3

# Проверка: если процесс умер — показываем лог и выходим
if ! kill -0 $API_PID 2>/dev/null; then
    echo "!!! API-сервер упал. Лог:"
    cat ~/kali_api.log
    exit 1
fi

echo "=== 6. Проверка /health ==="
HEALTH=$(curl -s http://127.0.0.1:5000/health)
echo "$HEALTH"

# Проверяем, что health вернул healthy (простая проверка на наличие строки)
if echo "$HEALTH" | grep -q '"status":"healthy"'; then
    echo "✅ API-сервер работает."
else
    echo "❌ API-сервер не отвечает корректно. Лог:"
    cat ~/kali_api.log
    exit 1
fi

echo "=== 7. Готово ==="
echo ""
echo "Запустите ollmcp так:"
echo "  source ~/ollmcp-venv/bin/activate"
echo "  ollmcp --servers-json ~/kali-mcp.json --model qwen2.5:7b"
echo ""
echo "В интерфейсе ollmcp: /rc (сброс конфига, включает все инструменты), затем команда."