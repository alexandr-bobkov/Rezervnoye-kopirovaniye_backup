#!/bin/bash

# --- НАСТРОЙКИ ---
SOURCE="$HOME/"
REMOTE_USER="user"
REMOTE_HOST="192.168.32.130"  # ЗАМЕНИТЕ НА ВАШ IP
BACKUP_ROOT="/tmp/backups"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
CURRENT_BACKUP="$BACKUP_ROOT/$TIMESTAMP"
LATEST_LINK="$BACKUP_ROOT/latest"

echo "--- Старт инкрементного бэкапа: $TIMESTAMP ---"

# 1. Подготовка структуры на сервере
ssh $REMOTE_USER@$REMOTE_HOST "mkdir -p $BACKUP_ROOT"

# 2. Запуск rsync
# Ссылка ../latest ищется относительно создаваемой папки бэкапа
if rsync -avz --delete --exclude='.*/' \
      --link-dest="../latest" \
      "$SOURCE" "$REMOTE_USER@$REMOTE_HOST:$CURRENT_BACKUP"; then
    
    echo "[OK] Данные переданы успешно."
    
    # 3. Обновление ссылки и ротация через алфавитную сортировку
    ssh $REMOTE_USER@$REMOTE_HOST "
        cd $BACKUP_ROOT
        
        # Находим самую новую папку (последняя в алфавитном списке)
        ACTUAL_NEWEST=\$(ls -1 | grep '^20' | sort | tail -n 1)
        
        if [ -n \"\$ACTUAL_NEWEST\" ]; then
            ln -snf \"\$ACTUAL_NEWEST\" latest
            echo \"Ссылка latest теперь указывает на: \$ACTUAL_NEWEST\"
        fi
        
        # Ротация: сортируем от новых к старым и удаляем всё после 5-й
        OLD_BACKUPS=\$(ls -1 | grep '^20' | sort -r | tail -n +6)
        
        if [ -n \"\$OLD_BACKUPS\" ]; then
            echo \"Удаляю лишние копии: \$OLD_BACKUPS\"
            rm -rf \$OLD_BACKUPS
        else
            echo \"В хранилище 5 или менее копий. Удаление не требуется.\"
        fi
    "
else
    echo "[ERROR] Ошибка rsync! Ссылка latest не обновлена."
    exit 1
fi

echo "--- Завершено ---"
