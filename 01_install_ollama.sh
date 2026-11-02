#!/bin/bash
# 01_install_ollama.sh
# Запускать на Kali с правами sudo
# После успешного выполнения сделайте снапшот ВМ.

set -e

echo "=== 1. Установка Ollama ==="
if ! command -v ollama &> /dev/null; then
    curl -fsSL https://ollama.com/install.sh | sh
    sudo systemctl enable --now ollama
    sleep 2
else
    echo "Ollama уже установлена."
fi
ollama --version

echo "=== 2. Загрузка модели qwen2.5:7b ==="
ollama pull qwen2.5:7b

echo "=== 3. Проверка ==="
ollama list

echo ""
echo "✅ Часть 1 завершена. Сделайте снапшот ВМ, затем запустите 02_install_mcp.sh"