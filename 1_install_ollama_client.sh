#!/bin/bash
# install_ollama_client.sh
# Запускать на VM1 (Ubuntu/Debian) с правами sudo

set -e

echo "=== 1. Установка Ollama ==="
curl -fsSL https://ollama.com/install.sh | sh

echo "=== 2. Запуск сервиса Ollama ==="
sudo systemctl enable --now ollama
sleep 2
ollama --version

echo "=== 3. Загрузка модели (пример: qwen2.5:7b) ==="
# Для CPU-режима лучше брать модель поменьше, например qwen2.5:3b или 7b
ollama pull qwen2.5:7b

echo "=== 4. Установка Python-клиента ollmcp ==="
# Требуется Python 3.10+
sudo apt update
sudo apt install -y python3 python3-pip python3-venv

# Рекомендуется использовать venv, чтобы не засорять систему
python3 -m venv ~/ollmcp-venv
source ~/ollmcp-venv/bin/activate
pip install --upgrade pip
pip install ollmcp

echo "=== 5. Запуск клиента для подключения к Kali ==="
# ВАЖНО: замените KALI_IP на реальный IP вашей Kali VM
KALI_IP="10.10.10.20"  # <-- ИЗМЕНИТЕ ПРИ НЕОБХОДИМОСТИ

echo "Клиент запустится в интерактивном режиме."
echo "Убедитесь, что на Kali уже запущен MCP-сервер."
echo "Команда: ollmcp --mcp-server-url http://${KALI_IP}:5000 --model qwen2.5:7b"
echo ""

# Раскомментируйте строку ниже для автоматического запуска клиента
# ollmcp --mcp-server-url "http://${KALI_IP}:5000" --model "qwen2.5:7b"