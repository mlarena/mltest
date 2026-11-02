#!/bin/bash
# setup_models_multi.sh
# Запускать на VM1 (Ubuntu/Debian) с правами sudo
# ВНИМАНИЕ: на CPU-виртуалке загрузка и запуск 10B модели будут ОЧЕНЬ медленными

set -e

KALI_IP="192.168.235.136"          # <-- IP вашей Kali VM
KALI_PORT="5000"
CLIENT_VENV="$HOME/ollmcp-venv"

echo "=== 1. Установка Ollama (если ещё не установлена) ==="
if ! command -v ollama &> /dev/null; then
    curl -fsSL https://ollama.com/install.sh | sh
    sudo systemctl enable --now ollama
    sleep 2
else
    echo "Ollama уже установлена."
fi
ollama --version

echo "=== 2. Загрузка моделей ==="

# --- Маленькие модели (быстрые на CPU) ---
echo "--- Llama 3.2 3B ---"
ollama pull llama3.2:3b

echo "--- Qwen2.5-Coder 1.5B ---"
ollama pull qwen2.5-coder:1.5b

# --- Средние модели (медленнее, но умнее) ---
echo "--- Qwen2.5 7B ---"
ollama pull qwen2.5:7b

echo "--- Llama 3.1 8B ---"
ollama pull llama3.1:8b

# --- Mythoseek 10B (специализированная security-модель) ---
# В реестре Ollama её нет. Используем GGUF с HuggingFace через hf.co/ shortcut.
# Q4_K_M — разумный компромисс качества/размера (около 5.7 GB по данным карточки модели).
echo "--- Mythoseek 10B (Q4_K_M, ~5.7GB) ---"
ollama run hf.co/mradermacher/Mythoseek-GGUF:Q4_K_M

echo "=== 3. Проверка загруженных моделей ==="
ollama list

echo "=== 4. Установка Python-клиента ollmcp (если ещё нет) ==="
if [ ! -d "$CLIENT_VENV" ]; then
    sudo apt update
    sudo apt install -y python3 python3-pip python3-venv
    python3 -m venv "$CLIENT_VENV"
fi
source "$CLIENT_VENV/bin/activate"
pip install --upgrade pip
pip install ollmcp

echo "=== 5. Готово. Команды для запуска клиента с нужной моделью: ==="
echo "source $CLIENT_VENV/bin/activate"
echo "ollmcp --mcp-server-url http://${KALI_IP}:${KALI_PORT} --model <MODEL_NAME>"
echo ""
echo "Доступные модели (из ollama list):"
ollama list