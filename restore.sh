#!/bin/bash

# --- НАСТРОЙКИ (должны совпадать с backup_inkriment.sh) ---
REMOTE_USER="user"
REMOTE_HOST="192.168.32.130"  # IP принимающего сервера
BACKUP_ROOT="/tmp/backups"
RESTORE_PATH="$HOME/restored_data"

echo "=== Мастер восстановления данных ==="

# 1. Получаем список бэкапов, отсортированный от новых к старым
echo "Запрос списка копий с сервера..."
BACKUPS=$(ssh $REMOTE_USER@$REMOTE_HOST "ls -1 $BACKUP_ROOT | grep '^20' | sort -r")

if [ -z "$BACKUPS" ]; then
    echo "Ошибка: Резервные копии не найдены в $BACKUP_ROOT"
    exit 1
fi

# 2. Интерактивное меню
echo "Выберите копию для восстановления (1 — самая свежая):"
PS3="Введите номер: "

select SELECTED_BACKUP in $BACKUPS; do
    if [ -n "$SELECTED_BACKUP" ]; then
        echo "--> Выбрана точка: $SELECTED_BACKUP"
        
        # Подготовка локальной папки
        echo "Подготовка папки $RESTORE_PATH..."
        [ -d "$RESTORE_PATH" ] && rm -rf "$RESTORE_PATH"
        mkdir -p "$RESTORE_PATH"
        
        # 3. Копирование данных обратно с сервера
        echo "Начинаю загрузку данных..."
        if rsync -avz "$REMOTE_USER@$REMOTE_HOST:$BACKUP_ROOT/$SELECTED_BACKUP/" "$RESTORE_PATH/"; then
            echo "=== Успех! Данные восстановлены в: $RESTORE_PATH ==="
        else
            echo "!!! Произошла ошибка при передаче данных через rsync."
        fi
        break
    else
        echo "Неверный выбор. Пожалуйста, введите число из списка."
    fi
done
