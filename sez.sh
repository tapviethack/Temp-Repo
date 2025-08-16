#!/bin/bash

read -p "Nhập link GoFile (vd: https://gofile.io/d/abcdxxx): " GOFILE_URL
FILE_ID=$(echo "$GOFILE_URL" | sed -E 's#.*/d/([^/]+).*#\1#')

DEST_DIR="$HOME/sdcard/Download"
mkdir -p "$DEST_DIR"

# Thử API mới trước
response=$(curl -s "https://api.gofile.io/contents/$FILE_ID")

# Nếu không có status ok thì fallback về API cũ
if ! echo "$response" | grep -q '"status":"ok"'; then
    response=$(curl -s "https://api.gofile.io/getContent?contentId=$FILE_ID&websiteToken=12345")
fi

# Nếu vẫn không ok thì báo lỗi
if ! echo "$response" | grep -q '"status":"ok"'; then
    echo "[!] Lỗi: Không thể lấy dữ liệu từ GoFile"
    echo "$response"
    exit 1
fi

# Lấy link và tên file
links=$(echo "$response" | grep -o '"link":"[^"]*' | sed 's/\\u0026/\&/g' | cut -d'"' -f4)
names=$(echo "$response" | grep -o '"name":"[^"]*' | cut -d'"' -f4)

while read -r url && read -r name <&3; do
    echo "[*] Đang tải: $name"
    curl -L --output "$DEST_DIR/$name" "$url"
done <<< "$links" 3<<< "$names"

echo "[✓] Hoàn tất. File đã được lưu ở $DEST_DIR"
