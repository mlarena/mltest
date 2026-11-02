#!/bin/bash
# install_kali_mcp_server.sh
# Запускать на Kali VM с правами sudo

set -e

echo "=== 1. Обновление и установка зависимостей ==="
sudo apt update
sudo apt install -y python3 python3-pip python3-venv git

# Установка инструментов, которые будет вызывать агент
sudo apt install -y nmap gobuster sqlmap curl wget ffuf dirb nikto

echo "=== 2. Установка MCP-Kali-Server ==="
# Вариант А: через пакет (если доступен в вашей версии Kali)
# sudo apt install -y mcp-kali-server

# Вариант Б: из исходников (рекомендуется для контроля версии)
if [ ! -d ~/MCP-Kali-Server ]; then
    git clone https://github.com/Wh0am123/MCP-Kali-Server.git ~/MCP-Kali-Server
fi
cd ~/MCP-Kali-Server

# Создаём venv и ставим зависимости
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo "=== 3. Запуск MCP-сервера ==="
echo "Сервер будет доступен по адресу http://0.0.0.0:5000"
echo "Убедитесь, что файрвол Kali разрешает входящие на порт 5000 от VM1."
echo ""

# Запуск сервера (в фоне или на переднем плане — на ваше усмотрение)
# Для отладки лучше запустить на переднем плане в отдельном терминале:
# ./server.py --ip 0.0.0.0 --port 5000

# Пример запуска в фоне с логом:
nohup ./server.py --ip 0.0.0.0 --port 5000 > ~/kali_mcp_server.log 2>&1 &
echo "Сервер запущен в фоне. Лог: ~/kali_mcp_server.log"