#!/bin/bash
# all_in_one_kali.sh
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

echo "=== 3. Установка mcp-kali-server и инструментов ==="
sudo apt update
sudo apt install -y mcp-kali-server nmap gobuster nikto dirb python3-pip python3-venv

echo "=== 4. Установка ollmcp в venv ==="
VENV="$HOME/ollmcp-venv"
if [ ! -d "$VENV" ]; then
    python3 -m venv "$VENV"
fi
source "$VENV/bin/activate"
pip install --upgrade pip
pip install ollmcp

echo "=== 5. Запуск API-сервера Kali (порт 5000, только localhost) ==="
pkill -f kali-server-mcp 2>/dev/null || true
sleep 1
nohup kali-server-mcp --ip 127.0.0.1 --port 5000 > ~/kali_api.log 2>&1 &
echo "API-сервер запущен (PID: $!)"
sleep 2
curl -s http://127.0.0.1:5000/health
echo ""

echo "=== 6. Готово ==="
echo "Теперь запустите ollmcp с мостом mcp-server:"
echo ""
echo "  source ~/ollmcp-venv/bin/activate"
echo "  ollmcp --mcp-server \"mcp-server --server http://127.0.0.1:5000\" --model qwen2.5:7b"
echo ""
echo "В интерфейсе ollmcp: /tools -> a -> s, затем команда модели."