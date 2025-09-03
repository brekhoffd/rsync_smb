#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Обробка помилок
trap 'echo "Сталася помилка на рядку $LINENO"; exit 1' ERR

# Налаштування адреси сервера та точки монтування
SERVER_IP="<server_ip>"          # Вказати IP-адресу віддаленого SMB-сервера без <...>
FOLDER_NAME="<folder_name>"      # Вказати ім'я папки для монтування без <...>
MOUNT_POINT="/mnt/$FOLDER_NAME"  # Вказати точку монтування

# Список всіх папок для синхронізації та їх розташування у місці призначення (вказати свої значення)
declare -A shares=(
        [Folder_1]="/folder/1"
        [Folder_2]="/folder/2"
        [Folder_3]="/folder/3"
)

# Створення точки монтування SMB-шари без помилки, якщо така папка вже існує
sudo mkdir /mnt/"$FOLDER_NAME" 2>/dev/null || true

# Функція для синхронізації даних SMB-шар
backup_share() {
        local share="$1"   # Назва SMB-шари на сервері
        local target="$2"  # Локальний каталог призначення
        echo
        echo "Синхронізація $share >>> $target"
        echo

        # Звільнення точки монтування без помилки, якщо нічого не примонтовано
        sudo umount "$MOUNT_POINT" 2>/dev/null || true

        # Монтування SMB-шари
        sudo mount -t cifs "//$SERVER_IP/$share" "$MOUNT_POINT" -o guest,iocharset=utf8,ro

        # Створення папки призначення
        sudo mkdir -p "$target"

        # Синхронізація даних
        sudo rsync -a --progress --delete-during "$MOUNT_POINT/" "$target"  # Додавання виключень ключем --exclude='<папка/ або шлях/до/файлу>'

        # Відмонтування SMB-шари
        sudo umount "$MOUNT_POINT"
}

# Цикл для синхронізації даних SMB-шар
for share in "${!shares[@]}"; do
        backup_share "$share" "${shares[$share]}"
done

echo "Синхронізація завершена!"
