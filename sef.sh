#!/bin/bash

# Cài curl và jq nếu chưa có
if ! command -v curl >/dev/null 2>&1; then
    echo "[*] Đang cài curl..."
    pkg install -y curl
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "[*] Đang cài jq..."
    pkg install -y jq
fi

# Nhập link GoFile
read -p "Nhập link GoFile (ví dụ https://gofile.io/d/abcdxxx): " GOFILE_URL

# Lấy ID từ link
FILE_ID=$(echo "$GOFILE_URL" | sed -E 's#.*/d/([^/?]+).*#\1#')

if [ -z "$FILE_ID" ]; then
    echo "[!] Không tìm thấy FILE_ID trong link"
    exit 1
fi

echo "[*] Đang lấy thông tin file với ID: $FILE_ID"

# Gọi API content
API_URL="https://api.gofile.io/getContent?contentId=$FILE_ID&cache=true"
response=$(curl -s "$API_URL")

# Kiểm tra response
if ! echo "$response" | grep -q '"status":"ok"'; then
    echo "[!] Lỗi khi gọi API. Response:"
    echo "$response"
    exit 1
fi

# Lấy link tải đầu tiên
DL_URL=$(echo "$response" | jq -r '.data.contents[]?.link' | head -n 1)

if [ -z "$DL_URL" ] || [ "$DL_URL" = "null" ]; then
    echo "[!] Không lấy được link tải từ API"
    exit 1
fi

# Lấy tên file
FILENAME=$(basename "$DL_URL")

echo "[*] Bắt đầu tải: $FILENAME"
curl -L --progress-bar "$DL_URL" -o "/sdcard/Download/$FILENAME"

echo "[+] Tải xong! File lưu tại: /sdcard/Download/$FILENAME"
