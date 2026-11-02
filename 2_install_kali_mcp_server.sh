#!/bin/bash
# install_kali_mcp_server.sh (fixed)
# Запускать на Kali VM с правами sudo

set -e

echo "=== 0. Проверка сетевого подключения ==="
if ! ping -c 2 http.kali.org &>/dev/null; then
    echo "Предупреждение: не удалось пропинговать http.kali.org, возможно проблема с сетью."
    echo "Попробуем переключиться на зеркало Cloudflare..."
    # Переключение на зеркало Cloudflare, рекомендованное официальной командой Kali [citation:14]
    sudo sed -i 's|http://http.kali.org/kali|http://kali.download/kali|g' /etc/apt/sources.list 2>/dev/null || true
    sudo sed -i 's|http://http.kali.org/kali|http://kali.download/kali|g' /etc/apt/sources.list.d/kali.sources 2>/dev/null || true
fi

echo "=== 1. Обновление индексов apt и исправление недостающих пакетов ==="
sudo apt update || true
# Если update выдал ошибки, пытаемся исправить с помощью fix-missing [citation:1]
sudo apt install --fix-missing -y || true

echo "=== 2. Установка базовых зависимостей и инструментов ==="
# Устанавливаем по одному, чтобы сбой одного пакета не прерывал весь процесс
for pkg in python3 python3-pip python3-venv git nmap gobuster sqlmap curl wget ffuf dirb nikto; do
    echo "--- Установка: $pkg ---"
    sudo apt install -y "$pkg" || echo "Предупреждение: $pkg не установлен, пропускаем"
done

echo "=== 3. Установка MCP-Kali-Server (официальный пакет Kali) ==="
# Официальный пакет надёжнее клонирования из GitHub, команда запуска — kali-server-mcp [citation:3][citation:9]
sudo apt install -y mcp-kali-server || {
    echo "Пакетная установка не удалась, пробуем альтернативный метод клонирования из GitHub..."
    if [ ! -d ~/MCP-Kali-Server ]; then
        git clone https://github.com/Wh0am123/MCP-Kali-Server.git ~/MCP-Kali-Server
    fi
    cd ~/MCP-Kali-Server
    python3 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    # При клонировании имя команды запуска — ./server.py
    SERVER_CMD="./server.py"
}

echo "=== 4. Запуск MCP-сервера ==="
# Определяем команду запуска: если установлено из пакета, используем kali-server-mcp, иначе server.py
if command -v kali-server-mcp &>/dev/null; then
    SERVER_CMD="kali-server-mcp"
elif [ -f ~/MCP-Kali-Server/server.py ]; then
    cd ~/MCP-Kali-Server && source .venv/bin/activate
    SERVER_CMD="./server.py"
else
    echo "ОШИБКА: MCP-сервер не найден."
    exit 1
fi

echo "Запуск: $SERVER_CMD --ip 0.0.0.0 --port 5000"
# Запуск в фоне
nohup $SERVER_CMD --ip 0.0.0.0 --port 5000 > ~/kali_mcp_server.log 2>&1 &
echo "Сервер запущен в фоне, PID: $!"
echo "Лог: ~/kali_mcp_server.log"
echo ""
echo "Проверка: curl http://127.0.0.1:5000"