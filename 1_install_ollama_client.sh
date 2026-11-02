#!/bin/bash
# 1_install_ollama_client.sh (упрощённый)
# Запускать на VM1 (192.168.235.134) с правами sudo

set -e

echo "=== 1. Установка Ollama ==="
if ! command -v ollama &> /dev/null; then
    curl -fsSL https://ollama.com/install.sh | sh
    sudo systemctl enable --now ollama
    sleep 2
fi
ollama --version

echo "=== 2. Загрузка модели для старта (qwen2.5:7b) ==="
ollama pull qwen2.5:7b

echo "=== 3. Установка ollmcp в venv ==="
CLIENT_VENV="$HOME/ollmcp-venv"
if [ ! -d "$CLIENT_VENV" ]; then
    sudo apt update
    sudo apt install -y python3 python3-pip python3-venv
    python3 -m venv "$CLIENT_VENV"
fi
source "$CLIENT_VENV/bin/activate"
pip install --upgrade pip
pip install ollmcp

echo "=== 4. Готово ==="
echo "Модели:"
ollama list
echo ""
echo "Дальше: запустите скрипт на Kali, затем вернитесь сюда и выполните:"
echo "source $CLIENT_VENV/bin/activate"
echo "ollmcp --mcp-server 'python3 /путь/к/client.py --server http://192.168.235.136:5000' --model qwen2.5:7b"