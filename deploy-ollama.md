Отлично! У вас есть отличный набор моделей для тестов. Теперь давайте создадим **полную инструкцию** и **bash-скрипт** для автоматического развертывания, которые вы сможете использовать как на ВМ, так и на физическом сервере.

---

## 📄 Инструкция по развертыванию Ollama + Open WebUI

### Предварительные требования
- **ОС:** Ubuntu 22.04 LTS или новее (также работает на Debian)
- **Интернет:** Для скачивания моделей (~5-10 ГБ трафика)
- **Ресурсы:** Минимум 4 ГБ ОЗУ, 20 ГБ дискового пространства (рекомендуется 8+ ГБ ОЗУ и 50+ ГБ диска)

---

### Шаг 1. Установка Ollama

```bash
# Скачать и установить Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Проверить, что сервис запустился
systemctl status ollama
```

### Шаг 2. Настройка сети (важно для Open WebUI)

Ollama по умолчанию слушает только на `127.0.0.1`. Чтобы веб-интерфейс в контейнере мог к нему обращаться, нужно разрешить прослушивание на всех интерфейсах:

```bash
# Остановить сервис
sudo systemctl stop ollama

# Создать конфигурационный файл с переменной окружения
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null <<EOF
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
EOF

# Перезагрузить конфигурацию systemd и запустить сервис
sudo systemctl daemon-reload
sudo systemctl start ollama
```

### Шаг 3. Скачивание моделей (выберите нужные)

```bash
# Базовые модели (для тестов)
ollama pull tinyllama:1.1b    # 637 МБ, очень быстрая
ollama pull phi3:latest        # 2.2 ГБ, хорошая логика
ollama pull llama3.2:3b        # 2.0 ГБ, универсальная
ollama pull gemma2:2b          # 1.6 ГБ, от Google
ollama pull moondream:latest   # 1.7 ГБ, мультимодальная (работа с изображениями)

# Проверить, что модели скачались
ollama list
```

**Совет:** При медленном интернете или частых обрывах используйте:
```bash
export OLLAMA_DOWNLOAD_PARTS=4   # Уменьшить число потоков для стабильности
```
Если загрузка зависла, нажмите `Ctrl+C` и сразу повторите `ollama pull` — скачивание продолжится с того же места.

### Шаг 4. Установка Docker и Open WebUI

```bash
# Установить Docker (если ещё не установлен)
sudo apt update
sudo apt install docker.io -y

# Запустить контейнер Open WebUI
docker run -d -p 3000:8080 \
  --add-host=host.docker.internal:host-gateway \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  -v open-webui:/app/backend/data \
  --name open-webui --restart always \
  ghcr.io/open-webui/open-webui:main
```

### Шаг 5. Доступ к интерфейсу

Узнайте IP-адрес вашего сервера:
```bash
ip a | grep inet | grep -v 127.0.0.1
```

Откройте браузер и перейдите по адресу:  
`http://<IP-адрес-вашего-сервера>:3000`

При первом входе создайте аккаунт администратора (локальный). Затем в выпадающем списке выберите любую модель и начинайте диалог.

### Шаг 6. Проверка API (для скриптов)

```bash
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2:3b",
  "prompt": "Привет! Напиши короткий код на Python",
  "stream": false
}'
```

---
