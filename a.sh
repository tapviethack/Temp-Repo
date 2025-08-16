#!/bin/bash

# ==== CÀI ĐẶT PHỤ THUỘC (Termux/Ubuntu) ====
if ! command -v curl >/dev/null 2>&1; then
    echo "[*] Cài curl..."
    pkg install -y curl || apt-get install -y curl
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "[*] Cài jq..."
    pkg install -y jq || apt-get install -y jq
fi

# ==== NHẬP LINK ====
read -p "Nhập link GoFile (vd: https://gofile.io/d/abcdxxx): " GOFILE_URL

# Lấy contentId từ link
FILE_ID=$(echo "$GOFILE_URL" | sed -E 's#.*/d/([^/]+).*#\1#')

echo "[*] Content ID: $FILE_ID"

# Lấy server khả dụng
SERVER=$(curl -s https://api.gofile.io/servers | jq -r '.data.servers[0].name')

if [ -z "$SERVER" ] || [ "$SERVER" = "null" ]; then
    echo "[!] Không thể lấy server từ GoFile API"
    exit 1
fi

echo "[*] Sử dụng server: $SERVER"

# Lấy metadata file
META=$(curl -s "https://api.gofile.io/contents/$FILE_ID?server=$SERVER")

if ! echo "$META" | grep -q '"status":"ok"'; then
    echo "[!] Lỗi: Không lấy được metadata"
    echo "$META"
    exit 1
fi

# Lấy link download đầu tiên
DL_LINK=$(echo "$META" | jq -r '.data.contents[]?.link' | head -n1)

if [ -z "$DL_LINK" ] || [ "$DL_LINK" = "null" ]; then
    echo "[!] Không tìm thấy link tải"
    exit 1
fi

# Lấy tên file
FILENAME=$(basename "$DL_LINK")

echo "[*] Tải về: $FILENAME"

# Tải về sdcard/Download
DEST="$HOME/storage/downloads/$FILENAME"
curl -L "$DL_LINK" -o "$DEST"

echo "[+] Đã tải về: $DEST"
