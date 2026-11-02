#!/bin/bash
# 2_install_kali_mcp_server.sh (упрощённый)
# Запускать на Kali (192.168.235.136) с правами sudo

set -e

echo "=== 1. Установка mcp-kali-server и инструментов ==="
sudo apt update
sudo apt install -y mcp-kali-server nmap gobuster nikto dirb

echo "=== 2. Запуск API-сервера на всех интерфейсах ==="
# Останавливаем старый, если был
pkill -f kali-server-mcp 2>/dev/null || true
sleep 1

# Запуск в фоне с логом
nohup kali-server-mcp --ip 0.0.0.0 --port 5000 > ~/kali_api.log 2>&1 &
echo "API-сервер запущен (PID: $!)"
echo "Лог: ~/kali_api.log"
sleep 2

echo "=== 3. Проверка ==="
curl -s http://127.0.0.1:5000/health
echo ""
echo ""
echo "=== 4. Готово ==="
echo "На VM1 выполните:"
echo "  source ~/ollmcp-venv/bin/activate"
echo "  ollmcp --mcp-server 'mcp-server --server http://192.168.235.136:5000' --model qwen2.5:7b"
echo ""
echo "ПРИМЕЧАНИЕ: если ollmcp на VM1 не находит команду mcp-server,"
echo "скопируйте её путь с Kali или укажите полный путь к client.py."