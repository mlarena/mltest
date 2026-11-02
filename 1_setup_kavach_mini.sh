#!/bin/bash
# setup_kavach_mini.sh
# Запускать на VM1 после установки Ollama

set -e

MODEL_NAME="kavach-mini"
GGUF_URL="https://huggingface.co/TNSA/Kavach-1-Mini-LoRA-INT4/resolve/main/Kavach-1-Mini-LoRA-INT4.gguf"
# Примечание: URL может потребовать уточнения. Если 404 — проверьте страницу модели на HuggingFace.
# Альтернативно можно использовать MXFP4 или INT8, если INT4 недоступен.

WORK_DIR="$HOME/kavach-mini-setup"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo "=== 1. Скачивание GGUF (INT4, ~0.5GB) ==="
# Если wget недоступен, используйте curl -L
if command -v wget &> /dev/null; then
    wget --continue "$GGUF_URL" -O kavach.gguf
else
    curl -L "$GGUF_URL" -o kavach.gguf
fi

echo "=== 2. Создание Modelfile ==="
cat > Modelfile << 'EOF'
FROM ./kavach.gguf
TEMPLATE "{{- if .System }}{{ .System }}{{ end }}{{- range .Messages }}{{- if eq .Role \"user\" }}<|im_start|>user\n{{ .Content }}<|im_end|>{{ else if eq .Role \"assistant\" }}<|im_start|>assistant\n{{ .Content }}<|im_end|>{{ end }}{{- end }}<|im_start|>assistant\n"
PARAMETER stop <|im_end|>
PARAMETER stop <|im_start|>
PARAMETER temperature 0.7
EOF

echo "=== 3. Создание модели в Ollama ==="
ollama create "$MODEL_NAME" -f Modelfile

echo "=== 4. Проверка ==="
ollama list | grep "$MODEL_NAME" && echo "Kavach-1-Mini успешно создана как $MODEL_NAME"

echo "=== 5. Запуск клиента с Kavach ==="
# Раскомментируйте для запуска:
# source ~/ollmcp-venv/bin/activate
# ollmcp --mcp-server-url "http://10.10.10.20:5000" --model "$MODEL_NAME"