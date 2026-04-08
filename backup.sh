#!/bin/bash

# Настройки по умолчанию (для работы через cron)
DEFAULT_SOURCE="$HOME/"
DEFAULT_TARGET="/tmp/backup"

# Проверяем, запущен ли скрипт в интерактивном режиме (есть ли терминал)
if [ -t 0 ]; then
    # Режим ручного запуска: спрашиваем пользователя
    echo "--- Интерактивный режим резервного копирования ---"
    
    read -p "Источник [$DEFAULT_SOURCE]: " SOURCE_DIR
    SOURCE_DIR=${SOURCE_DIR:-$DEFAULT_SOURCE} # Если нажать Enter, возьмет значение по умолчанию
    
    read -p "Назначение [$DEFAULT_TARGET]: " TARGET_DIR
    TARGET_DIR=${TARGET_DIR:-$DEFAULT_TARGET}
else
    # Режим cron: используем настройки по умолчанию без вопросов
    SOURCE_DIR=$DEFAULT_SOURCE
    TARGET_DIR=$DEFAULT_TARGET
fi

# Проверка источника
if [ ! -d "$SOURCE_DIR" ]; then
    logger "Backup error: Directory $SOURCE_DIR not found"
    exit 1
fi

# Создание папки назначения
mkdir -p "$TARGET_DIR"

# Запуск зеркалирования
if rsync -av --delete --checksum --exclude='.*/' "$SOURCE_DIR" "$TARGET_DIR"; then
    logger "Backup successful: $SOURCE_DIR to $TARGET_DIR"
else
    logger "Backup failed: $SOURCE_DIR to $TARGET_DIR"
fi
