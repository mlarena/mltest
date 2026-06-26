#!/bin/bash
set -e  # Остановка при любой ошибке

# Цветной вывод
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Развертывание Ollama + Open WebUI ===${NC}"

# Шаг 1: Установка Ollama
echo -e "${YELLOW}Установка Ollama...${NC}"
if ! command -v ollama &> /dev/null; then
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo -e "${GREEN}Ollama уже установлен${NC}"
fi

# Шаг 2: Настройка OLLAMA_HOST
echo -e "${YELLOW}Настройка OLLAMA_HOST на 0.0.0.0...${NC}"
sudo systemctl stop ollama || true
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null <<EOF
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
EOF
sudo systemctl daemon-reload
sudo systemctl start ollama
sleep 2  # Даем время серверу запуститься

# Шаг 3: Скачивание моделей
echo -e "${YELLOW}Скачивание базовых моделей (это может занять время)...${NC}"
export OLLAMA_DOWNLOAD_PARTS=4  # Стабильнее загрузка

# Проверяем наличие модели, если нет - скачиваем
download_model() {
    local model=$1
    if ! ollama list | grep -q "^$model"; then
        echo -e "${YELLOW}Скачивание $model...${NC}"
        ollama pull $model || {
            echo -e "${RED}Ошибка при скачивании $model. Проверьте интернет.${NC}"
            exit 1
        }
    else
        echo -e "${GREEN}$model уже скачан${NC}"
    fi
}

download_model "tinyllama:1.1b"
download_model "phi3:latest"
download_model "llama3.2:3b"
download_model "gemma2:2b"

download_model "deepseek-r1:1.5b"
download_model "deepseek-r1:7b"
#download_model "mistral:latest"
#download_model "ministral:latest"
#download_model "mistral-nemo:latest"
download_model "deepseek-coder:6.7b"
download_model "qwen2.5-coder:7b"
download_model "solar:10.7b"

# Command R 35B — если захотите попробовать что-то очень большое (около 20 ГБ) — НЕ РЕКОМЕНДУЮ для 32 ГБ ОЗУ!
# ollama pull command-r:latest

# download_model "moondream:latest"  # раскомментируйте, если нужна

echo -e "${GREEN}Скачанные модели:${NC}"
ollama list

# Шаг 4: Установка Docker и запуск Open WebUI
echo -e "${YELLOW}Установка Docker...${NC}"
if ! command -v docker &> /dev/null; then
    sudo apt update
    sudo apt install docker.io -y
else
    echo -e "${GREEN}Docker уже установлен${NC}"
fi

echo -e "${YELLOW}Запуск Open WebUI...${NC}"
docker rm -f open-webui 2>/dev/null || true
docker run -d -p 3000:8080 \
    --add-host=host.docker.internal:host-gateway \
    -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
    -v open-webui:/app/backend/data \
    --name open-webui --restart always \
    ghcr.io/open-webui/open-webui:main

# Шаг 5: Финальная информация
echo -e "${GREEN}=== Развертывание завершено! ===${NC}"
IP=$(ip a | grep inet | grep -v 127.0.0.1 | grep -v docker0 | awk '{print $2}' | cut -d/ -f1 | head -1)
echo -e "Откройте в браузере: ${GREEN}http://$IP:3000${NC}"
echo -e "При первом входе создайте локального администратора."
echo -e "Список моделей в системе:"
ollama list

# Проверка работы API
echo -e "${YELLOW}Проверка соединения с Ollama...${NC}"
curl -s http://localhost:11434/api/tags | grep -q "models" && echo -e "${GREEN}Ollama работает${NC}" || echo -e "${RED}Ошибка: Ollama не отвечает${NC}"